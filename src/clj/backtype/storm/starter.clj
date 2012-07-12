(ns backtype.storm.starter
  (:use [backtype.storm.util :only [current-classpath]])
  (:use [backtype.storm log])
  (:use [clojure.string :only [split]])
  (:require [clojure [set :as set]])
  (:import [java.net URL])
  (:import [java.io File])
  (:import [backtype.storm StormClassLoader])
  (:import [backtype.storm.utils Utils])
  (:gen-class))

(defn cal-server-jars [storm-home]
  ;; find the $STORM_HOME/lib directory
  (let [storm-lib (str storm-home "/lib")
        storm-home-file (File. storm-home)
        storm-home-files (vec (.listFiles storm-home-file))
        storm-home-jars (filter (fn [file]
                             (let [file-name (.getName file)
                                   jar? (.endsWith file-name ".jar")]
                               jar?))
                           storm-home-files)
        storm-lib-file (File. storm-lib)
        storm-deps (vec (.listFiles storm-lib-file))
        storm-deps (concat storm-home-jars storm-deps)
        storm-deps (conj storm-deps (File. (str storm-home "/log4j")))
        storm-deps (conj storm-deps (File. (str storm-home "/conf")))
        storm-deps (map #(.toURL %) storm-deps)]
    storm-deps))

(defn mk-remote-server-classloader []
  ;; calculate the jars to be included in the classloader
  (let [storm-home (System/getProperty "storm.home")
        urls (cal-server-jars storm-home)
        server-classloader (StormClassLoader/create urls)]
    server-classloader))

(defn mk-remote-user-classloader [^ClassLoader parent]
  (let [uberjar-path (System/getProperty "uberjar.path")
        user-classloader (StormClassLoader/create [uberjar-path] parent)]
    user-classloader))

(defn cal-storm-deps []
  (let [storm-deps (Utils/findAndReadConfigFile "storm.deps.yaml")
        storm-deps (into {} storm-deps)
        storm-deps (storm-deps "storm.deps")]
        storm-deps (set storm-deps)
    storm-deps))

(defn mk-local-server-classloader []
  (let [storm-deps (cal-storm-deps)
        classpath (current-classpath)
        ;; FIXME xumingmingv fix the path seperator
        classpath (split classpath #":")
        jar-name->path (into {} (for [jarpath classpath]
                                  {(-> jarpath (split #"/") last) jarpath}))

        server-dep-paths (for [dep storm-deps]
                           (jar-name->path dep))
        server-dep-paths (filter #(not (nil? %)) server-dep-paths)
        server-dep-paths (set server-dep-paths)
        _ (log-message "MM: jar-name->path: " jar-name->path)
        _ (log-message "MM: storm-deps: " (vec storm-deps))
        _ (log-message "MM: server-dep-paths: " server-dep-paths)
        server-classloader (StormClassLoader/create server-dep-paths)]
    server-classloader))

(defn mk-local-user-classloader [^ClassLoader server-classloader]
  (let [storm-deps (cal-storm-deps)
        classpath (current-classpath)
        ;; FIXME xumingmingv fix the path seperator
        classpath (split classpath #":")
        classpath (set classpath)
        jar-name->path (into {} (for [jarpath classpath]
                                  {(-> jarpath (split #"/") last) jarpath}))
        server-dep-paths (for [dep storm-deps]
                           (jar-name->path dep))
        server-dep-paths (filter #(not (nil? %)) server-dep-paths)
        server-dep-paths (set server-dep-paths)
        user-dep-paths (set/difference classpath server-dep-paths)
        user-classloader (StormClassLoader/create user-dep-paths server-classloader)]
    user-classloader))

(defn -main [& args]
  ;; create ServerClassLoader
  (let [storm-home (System/getProperty "storm.home")
        server-classloader (mk-remote-server-classloader)
        _ (println "args: " args)
        daemon-name (first args)
        rest-args (rest args)
        daemon-args (make-array String (count rest-args))
        _ (doseq [arg rest-args
                  i   (range (count rest-args))]
            (aset daemon-args i arg))
        daemon-class-name (str "backtype.storm.daemon." daemon-name)
        daemon-class (.loadClass server-classloader daemon-class-name)
        args-class (class (make-array String 0))
        classes (make-array Class 1)
        _ (aset classes 0 args-class)
        main-method (.getMethod daemon-class "main" classes)
        main-method-args (make-array Object 1)
        _ (aset main-method-args 0 daemon-args)
        _ (.setContextClassLoader (Thread/currentThread) server-classloader)
        _ (println "main-method-args: " main-method-args)]
    (println "daemon class: " (.getClassLoader daemon-class))
    (.invoke main-method nil main-method-args)))