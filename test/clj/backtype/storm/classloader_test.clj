(ns backtype.storm.classloader-test
  (:import [java.io File])
  (:import [java.net URL]))

(def afile (File. "/tmp/"))
(def aurl (.toURL afile))
(def urlarr (make-array URL 1))
(aset urlarr 0 aurl)
