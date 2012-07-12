(ns backtype.storm.daemon.test
  (:import [org.apache.zookeeper KeeperException KeeperException$NoNodeException])
  (:gen-class))

(defn -main []
  (doseq [i (range 600)]
    (println "time: " i)
    (let [clazz (.loadClass (.getContextClassLoader (Thread/currentThread)) "com.netflix.curator.retry.RetryNTimes")]
      (println "clazz: " clazz))
    (Thread/sleep 1000)))