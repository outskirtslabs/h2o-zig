#!/usr/bin/env bb

(ns tasks
  (:require [babashka.process :as p]
            [clojure.string :as str]))

(def package-file "pkgs/h2o-zig.nix")

(def fetchurl-entry-re
  #"(?ms)([A-Za-z0-9]+Src)\s*=\s*fetchurl\s*\{\s*url\s*=\s*\"([^\"]+)\";\s*hash\s*=\s*\"([^\"]+)\";")

(defn- parse-entries
  [content]
  (->> (re-seq fetchurl-entry-re content)
       (mapv (fn [[_ name url hash]]
               {:name name :url url :hash hash}))))

(defn- prefetch-hash
  [url]
  (let [{:keys [out err exit]} (p/shell {:out :string :err :string :continue true}
                                        "nix" "store" "prefetch-file" "--json" url)]
    (when-not (zero? exit)
      (throw (ex-info "Failed to prefetch dependency URL"
                      {:url url :exit exit :err err})))
    (let [hash (some-> (re-find #"\"hash\"\s*:\s*\"([^\"]+)\"" out) second)]
      (when-not (and hash (str/starts-with? hash "sha256-"))
        (throw (ex-info "Unexpected prefetch result"
                        {:url url :output out})))
      hash)))

(defn- replace-entry-hash
  [content {:keys [name url]} new-hash]
  (let [pattern (re-pattern
                 (str "(?ms)("
                      (java.util.regex.Pattern/quote name)
                      "\\s*=\\s*fetchurl\\s*\\{\\s*url\\s*=\\s*\""
                      (java.util.regex.Pattern/quote url)
                      "\";\\s*hash\\s*=\\s*\")([^\"]+)(\";)"))]
    (when-not (re-find pattern content)
      (throw (ex-info "Could not find matching fetchurl block for source"
                      {:name name :url url})))
    (str/replace content pattern (fn [[_ prefix _ suffix]]
                                   (str prefix new-hash suffix)))))

(defn update-h2o-zig-hashes
  "Recompute and update all fetchurl hashes in pkgs/h2o-zig.nix."
  []
  (let [content (slurp package-file)
        entries (parse-entries content)]
    (when (empty? entries)
      (throw (ex-info "No fetchurl entries found in package file"
                      {:file package-file})))
    (let [updates (mapv (fn [{:keys [name url hash] :as entry}]
                          (let [new-hash (prefetch-hash url)]
                            (assoc entry
                                   :new-hash new-hash
                                   :changed? (not= hash new-hash))))
                        entries)
          updated-content (reduce (fn [acc {:keys [new-hash] :as entry}]
                                    (replace-entry-hash acc entry new-hash))
                                  content
                                  updates)
          changed (filterv :changed? updates)]
      (when (not= content updated-content)
        (spit package-file updated-content))
      (if (seq changed)
        (do
          (println "Updated" package-file "hashes:")
          (doseq [{:keys [name hash new-hash]} changed]
            (println " -" name hash "->" new-hash)))
        (println package-file "hashes are already up to date."))
      (println "Checked" (count updates) "fetchurl entries."))))
