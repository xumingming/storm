(ns backtype.storm.wrapper
  (:import [java.util Map])
  (:import [backtype.storm.spout ISpout SpoutOutputCollector ISpout])
  (:import [backtype.storm.tuple Tuple])
  (:import [backtype.storm.task TopologyContext OutputCollector IBolt])
  (:import [backtype.storm.generated SpoutSpec Bolt]))

(defn wrap-fn [wrapper real-fn]
  (.setContextClassLoader (Thread/currentThread) (:user-classloader wrapper))
  (try
    (real-fn)
    (finally
       (.setContextClassLoader (Thread/currentThread) (:server-classloader wrapper)))))

(defrecord SpoutClassLoaderWrapper [^ISpout delegate ^ClassLoader server-classloader ^ClassLoader user-classloader]
  ISpout
  (^void open [this ^Map conf ^TopologyContext context ^SpoutOutputCollector collector]
    (wrap-fn this #(.open (:delegate this) conf context collector))
    )
  (^void close [this]
    (wrap-fn this #(.close (:delegate this)))
    )
  (^void activate [this]
    (wrap-fn this #(.activate (:delegate this)))
    )
  (^void deactivate [this]
    (wrap-fn this #(.deactivate (:delegate this)))
    )
  (^void nextTuple [this]
    (wrap-fn this #(.nextTuple (:delegate this)))
    )
  (^void ack [this msgId]
    (wrap-fn this #(.ack (:delegate this) msgId))
    )
  (^void fail [this msgId]
    (wrap-fn this #(.fail (:delegate this) msgId))
    ))

(defrecord BoltClassLoaderWrapper [^IBolt delegate ^ClassLoader server-classloader ^ClassLoader  user-classloader]
  IBolt
  (^void prepare [this ^Map conf ^TopologyContext context ^OutputCollector collector]
    (wrap-fn this #(.prepare (:delegate this) conf context collector)))
  (^void execute [this ^Tuple tuple]
    (wrap-fn this #(.execute (:delegate this) tuple)))
  (^void cleanup [this]
    (wrap-fn this #(.cleanup (:delegate this)))))
