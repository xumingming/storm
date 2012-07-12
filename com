src/clj/backtype/storm/cluster.clj:  (taskbeats [this storm-id task->node+port])
src/clj/backtype/storm/cluster.clj:  (report-error [this storm-id task-id error])
src/clj/backtype/storm/cluster.clj:  (errors [this storm-id task-id])
src/clj/backtype/storm/cluster.clj:(defn convert-task-beats [tasks worker-hb]
src/clj/backtype/storm/cluster.clj:  (let [task-stats (:task-stats worker-hb)]
src/clj/backtype/storm/cluster.clj:             (if (contains? task-stats t)
src/clj/backtype/storm/cluster.clj:                    :stats (get task-stats t)}})))
src/clj/backtype/storm/cluster.clj:      (taskbeats [this storm-id task->node+port]
src/clj/backtype/storm/cluster.clj:        ;; need to take task->node+port in explicitly so that we don't run into a situation where a 
src/clj/backtype/storm/cluster.clj:        (let [node+port->tasks (reverse-map task->node+port)
src/clj/backtype/storm/cluster.clj:                                     (convert-task-beats tasks)
src/clj/backtype/storm/daemon/common.clj:(defrecord Assignment [master-code-dir node->host task->node+port task->start-time-secs])
src/clj/backtype/storm/daemon/common.clj:(defrecord WorkerHeartbeat [time-secs storm-id task-ids port])
src/clj/backtype/storm/daemon/common.clj:(defn new-task-stats []
src/clj/backtype/storm/daemon/common.clj:(defn storm-task-ids [storm-cluster-state storm-id]
src/clj/backtype/storm/daemon/common.clj:  (keys (:task->node+port (.assignment-info storm-cluster-state storm-id nil))))
src/clj/backtype/storm/daemon/common.clj:        max-parallelism (storm-conf TOPOLOGY-MAX-TASK-PARALLELISM)
src/clj/backtype/storm/daemon/common.clj:(defn storm-task-info
src/clj/backtype/storm/daemon/nimbus.clj:   :task-heartbeats-cache (atom {})
src/clj/backtype/storm/daemon/nimbus.clj:                   [_ [node port]] (-> (.assignment-info storm-cluster-state a nil) :task->node+port)]
src/clj/backtype/storm/daemon/nimbus.clj:;; tracked through task-heartbeat-cache
src/clj/backtype/storm/daemon/nimbus.clj:(defn- alive-tasks [conf storm-id taskbeats task-ids task-start-times task-heartbeats-cache]
src/clj/backtype/storm/daemon/nimbus.clj:      (fn [task-id]
src/clj/backtype/storm/daemon/nimbus.clj:        (let [heartbeat (get taskbeats task-id)
src/clj/backtype/storm/daemon/nimbus.clj:               last-reported-time :task-reported-time} (get-in @task-heartbeats-cache
src/clj/backtype/storm/daemon/nimbus.clj:                                                               [storm-id task-id])
src/clj/backtype/storm/daemon/nimbus.clj:              task-start-time (get task-start-times task-id)
src/clj/backtype/storm/daemon/nimbus.clj:          (swap! task-heartbeats-cache
src/clj/backtype/storm/daemon/nimbus.clj:                 assoc-in [storm-id task-id]
src/clj/backtype/storm/daemon/nimbus.clj:                  :task-reported-time reported-time})
src/clj/backtype/storm/daemon/nimbus.clj:          (if (and task-start-time
src/clj/backtype/storm/daemon/nimbus.clj:                    (< (time-delta task-start-time)
src/clj/backtype/storm/daemon/nimbus.clj:                       (conf NIMBUS-TASK-LAUNCH-SECS))
src/clj/backtype/storm/daemon/nimbus.clj:                       (conf NIMBUS-TASK-TIMEOUT-SECS))
src/clj/backtype/storm/daemon/nimbus.clj:              (log-message "Task " storm-id ":" task-id " timed out")
src/clj/backtype/storm/daemon/nimbus.clj:      task-ids
src/clj/backtype/storm/daemon/nimbus.clj:(defn- keeper-slots [existing-slots num-task-ids num-workers]
src/clj/backtype/storm/daemon/nimbus.clj:    (let [distribution (atom (integer-divided num-task-ids num-workers))
src/clj/backtype/storm/daemon/nimbus.clj:      (doseq [[node+port task-list] existing-slots :let [task-count (count task-list)]]
src/clj/backtype/storm/daemon/nimbus.clj:        (when (pos? (get @distribution task-count 0))
src/clj/backtype/storm/daemon/nimbus.clj:          (swap! keepers assoc node+port task-list)
src/clj/backtype/storm/daemon/nimbus.clj:          (swap! distribution update-in [task-count] dec)
src/clj/backtype/storm/daemon/nimbus.clj:(defn compute-new-task->node+port [nimbus ^TopologyDetails topology-details existing-assignment callback scratch?]
src/clj/backtype/storm/daemon/nimbus.clj:        task-heartbeats-cache (:task-heartbeats-cache nimbus)
src/clj/backtype/storm/daemon/nimbus.clj:        all-task-ids (-> (read-storm-topology conf storm-id) (storm-task-info storm-conf) keys set)
src/clj/backtype/storm/daemon/nimbus.clj:        taskbeats (.taskbeats storm-cluster-state storm-id (:task->node+port existing-assignment))
src/clj/backtype/storm/daemon/nimbus.clj:        existing-assigned (reverse-map (:task->node+port existing-assignment))
src/clj/backtype/storm/daemon/nimbus.clj:                    all-task-ids
src/clj/backtype/storm/daemon/nimbus.clj:                                      all-task-ids (:task->start-time-secs existing-assignment)
src/clj/backtype/storm/daemon/nimbus.clj:                                      task-heartbeats-cache)))
src/clj/backtype/storm/daemon/nimbus.clj:                        (keeper-slots alive-assigned (count all-task-ids) total-slots-to-use))
src/clj/backtype/storm/daemon/nimbus.clj:        reassign-ids (sort (set/difference all-task-ids (set (apply concat (vals keep-assigned)))))
src/clj/backtype/storm/daemon/nimbus.clj:        stay-assignment (into {} (mapcat (fn [[node+port task-ids]] (for [id task-ids] [id node+port])) keep-assigned))]
src/clj/backtype/storm/daemon/nimbus.clj:(defn changed-ids [task->node+port new-task->node+port]
src/clj/backtype/storm/daemon/nimbus.clj:  (let [slot-assigned (reverse-map task->node+port)
src/clj/backtype/storm/daemon/nimbus.clj:        new-slot-assigned (reverse-map new-task->node+port)
src/clj/backtype/storm/daemon/nimbus.clj:  (let [old-slots (-> (:task->node+port existing-assignment)
src/clj/backtype/storm/daemon/nimbus.clj:        new-slots (-> (:task->node+port new-assignment)
src/clj/backtype/storm/daemon/nimbus.clj:;; get existing assignment (just the task->node+port map) -> default to {}
src/clj/backtype/storm/daemon/nimbus.clj:        task->node+port (compute-new-task->node+port nimbus
src/clj/backtype/storm/daemon/nimbus.clj:        reassign-ids (changed-ids (:task->node+port existing-assignment) task->node+port)
src/clj/backtype/storm/daemon/nimbus.clj:        start-times (merge (:task->start-time-secs existing-assignment)
src/clj/backtype/storm/daemon/nimbus.clj:                    (select-keys all-node->host (map first (vals task->node+port)))
src/clj/backtype/storm/daemon/nimbus.clj:                    task->node+port
src/clj/backtype/storm/daemon/nimbus.clj:            TOPOLOGY-MAX-TASK-PARALLELISM (total-conf TOPOLOGY-MAX-TASK-PARALLELISM)
src/clj/backtype/storm/daemon/nimbus.clj:          (swap! (:task-heartbeats-cache nimbus) dissoc id))
src/clj/backtype/storm/daemon/nimbus.clj:                                                            (-> (:task->node+port assignment)
src/clj/backtype/storm/daemon/nimbus.clj:                                                            (-> (:task->node+port assignment)
src/clj/backtype/storm/daemon/nimbus.clj:              task-info (storm-task-info (read-storm-topology conf storm-id) (read-storm-conf conf storm-id))
src/clj/backtype/storm/daemon/nimbus.clj:              taskbeats (.taskbeats storm-cluster-state storm-id (:task->node+port assignment))
src/clj/backtype/storm/daemon/nimbus.clj:              all-components (-> task-info reverse-map keys)
src/clj/backtype/storm/daemon/nimbus.clj:              errors (->> task-info
src/clj/backtype/storm/daemon/nimbus.clj:              task-summaries (if (empty? (:task->node+port assignment))
src/clj/backtype/storm/daemon/nimbus.clj:                               (dofor [[task component] task-info]
src/clj/backtype/storm/daemon/nimbus.clj:                                    (let [[node port] (get-in assignment [:task->node+port task])
src/clj/backtype/storm/daemon/nimbus.clj:                                                  (stats/thriftify-task-stats stats))]
src/clj/backtype/storm/daemon/nimbus.clj:                         task-summaries
src/clj/backtype/storm/daemon/supervisor.clj:(defrecord LocalAssignment [storm-id task-ids])
src/clj/backtype/storm/daemon/supervisor.clj:                         (:task->node+port assignment))
src/clj/backtype/storm/daemon/supervisor.clj:                          (for [[task-id [_ port]] my-tasks]
src/clj/backtype/storm/daemon/supervisor.clj:                            {port [task-id]}
src/clj/backtype/storm/daemon/supervisor.clj:    (into {} (for [[port task-ids] port-tasks]
src/clj/backtype/storm/daemon/supervisor.clj:               [(Integer. port) (LocalAssignment. storm-id task-ids)]
src/clj/backtype/storm/daemon/supervisor.clj:  "Returns map from port to struct containing :storm-id and :task-ids and :master-code-dir"
src/clj/backtype/storm/daemon/supervisor.clj:         (= (set (:task-ids worker-heartbeat)) (set (:task-ids local-assignment))))
src/clj/backtype/storm/daemon/task.clj:        task-getter (fn [i] (.get target-tasks i))]
src/clj/backtype/storm/daemon/task.clj:          task-getter))))
src/clj/backtype/storm/daemon/task.clj:(defn- get-task-object [topology component-id]
src/clj/backtype/storm/daemon/task.clj:(defmulti mk-task-stats class-selector)
src/clj/backtype/storm/daemon/task.clj:                        TOPOLOGY-MAX-TASK-PARALLELISM
src/clj/backtype/storm/daemon/task.clj:  (get-task-id [this]))
src/clj/backtype/storm/daemon/task.clj:  (let [task-id (.getThisTaskId topology-context)
src/clj/backtype/storm/daemon/task.clj:        receive-queue ((:receive-queue-map worker) task-id)
src/clj/backtype/storm/daemon/task.clj:        _ (log-message "Loading task " component-id ":" task-id)
src/clj/backtype/storm/daemon/task.clj:        task-info (.getTaskToComponent topology-context)
src/clj/backtype/storm/daemon/task.clj:        task-object (get-task-object (.getRawTopology topology-context)
src/clj/backtype/storm/daemon/task.clj:        task-stats (mk-task-stats task-object (sampling-rate storm-conf))
src/clj/backtype/storm/daemon/task.clj:        _ (doseq [klass (storm-conf TOPOLOGY-AUTO-TASK-HOOKS)]
src/clj/backtype/storm/daemon/task.clj:        component->tasks (reverse-map task-info)
src/clj/backtype/storm/daemon/task.clj:        task-readable-name (get-readable-name topology-context)
src/clj/backtype/storm/daemon/task.clj:        tasks-fn (fn ([^Integer out-task-id ^String stream ^List values]
src/clj/backtype/storm/daemon/task.clj:                          (log-message "Emitting direct: " out-task-id "; " task-readable-name " " stream " " values))
src/clj/backtype/storm/daemon/task.clj:                        (let [target-component (.getComponentId topology-context out-task-id)
src/clj/backtype/storm/daemon/task.clj:                              out-task-id (if grouping out-task-id)]
src/clj/backtype/storm/daemon/task.clj:                          (apply-hooks user-context .emit (EmitInfo. values stream [out-task-id]))
src/clj/backtype/storm/daemon/task.clj:                            (stats/emitted-tuple! task-stats stream)
src/clj/backtype/storm/daemon/task.clj:                            (if out-task-id
src/clj/backtype/storm/daemon/task.clj:                              (stats/transferred-tuples! task-stats stream 1)))
src/clj/backtype/storm/daemon/task.clj:                          (if out-task-id [out-task-id])
src/clj/backtype/storm/daemon/task.clj:                        (log-message "Emitting: " task-readable-name " " stream " " values))
src/clj/backtype/storm/daemon/task.clj:                          (stats/emitted-tuple! task-stats stream)
src/clj/backtype/storm/daemon/task.clj:                          (stats/transferred-tuples! task-stats stream (count out-tasks)))
src/clj/backtype/storm/daemon/task.clj:                                  (mk-executors task-object storm-conf receive-queue tasks-fn
src/clj/backtype/storm/daemon/task.clj:                                                user-context task-stats report-error))]
src/clj/backtype/storm/daemon/task.clj:    (log-message "Finished loading task " component-id ":" task-id)
src/clj/backtype/storm/daemon/task.clj:        (stats/render-stats! task-stats))
src/clj/backtype/storm/daemon/task.clj:      (get-task-id [this]
src/clj/backtype/storm/daemon/task.clj:        task-id )
src/clj/backtype/storm/daemon/task.clj:        (log-message "Shutting down task " storm-id ":" task-id)
src/clj/backtype/storm/daemon/task.clj:        (close-component task-object)
src/clj/backtype/storm/daemon/task.clj:        (log-message "Shut down task " storm-id ":" task-id))
src/clj/backtype/storm/daemon/task.clj:(defn- fail-spout-msg [^ISpout spout ^TopologyContext user-context storm-conf msg-id tuple-info time-delta task-stats sampler]
src/clj/backtype/storm/daemon/task.clj:    (stats/spout-failed-tuple! task-stats (:stream tuple-info) time-delta)
src/clj/backtype/storm/daemon/task.clj:(defn- ack-spout-msg [^ISpout spout ^TopologyContext user-context storm-conf msg-id tuple-info time-delta task-stats sampler]
src/clj/backtype/storm/daemon/task.clj:    (stats/spout-acked-tuple! task-stats (:stream tuple-info) time-delta)
src/clj/backtype/storm/daemon/task.clj:(defn mk-task-receiver [^LinkedBlockingQueue receive-queue ^KryoTupleDeserializer deserializer tuple-action-fn]
src/clj/backtype/storm/daemon/task.clj:                                task-stats report-error-fn]
src/clj/backtype/storm/daemon/task.clj:        task-id (.getThisTaskId topology-context)
src/clj/backtype/storm/daemon/task.clj:                       (.add event-queue #(fail-spout-msg spout user-context storm-conf spout-id tuple-info time-delta task-stats sampler)))
src/clj/backtype/storm/daemon/task.clj:        send-spout-msg (fn [out-stream-id values message-id out-task-id]
src/clj/backtype/storm/daemon/task.clj:                         (let [out-tasks (if out-task-id
src/clj/backtype/storm/daemon/task.clj:                                           (tasks-fn out-task-id out-stream-id values)
src/clj/backtype/storm/daemon/task.clj:                                                      task-id
src/clj/backtype/storm/daemon/task.clj:                                                [root-id (bit-xor-vals out-ids) task-id]))
src/clj/backtype/storm/daemon/task.clj:                               (.add event-queue #(ack-spout-msg spout user-context storm-conf message-id {:stream out-stream-id :values values} 0 task-stats sampler))))
src/clj/backtype/storm/daemon/task.clj:                           (^void emitDirect [this ^int out-task-id ^String stream-id
src/clj/backtype/storm/daemon/task.clj:                             (send-spout-msg stream-id tuple message-id out-task-id)
src/clj/backtype/storm/daemon/task.clj:                                                                                          tuple-finished-info time-delta task-stats sampler))
src/clj/backtype/storm/daemon/task.clj:                                                                                            tuple-finished-info time-delta task-stats sampler))
src/clj/backtype/storm/daemon/task.clj:    (log-message "Opening spout " component-id ":" task-id)
src/clj/backtype/storm/daemon/task.clj:    (log-message "Opened spout " component-id ":" task-id)
src/clj/backtype/storm/daemon/task.clj:               (log-message "Activating spout " component-id ":" task-id)
src/clj/backtype/storm/daemon/task.clj:               (log-message "Deactivating spout " component-id ":" task-id)
src/clj/backtype/storm/daemon/task.clj:         (mk-task-receiver receive-queue deserializer tuple-action-fn)
src/clj/backtype/storm/daemon/task.clj:                               task-stats report-error-fn]
src/clj/backtype/storm/daemon/task.clj:        task-id (.getThisTaskId topology-context)
src/clj/backtype/storm/daemon/task.clj:                                             task-id
src/clj/backtype/storm/daemon/task.clj:                                 (stats/bolt-acked-tuple! task-stats
src/clj/backtype/storm/daemon/task.clj:                                 (stats/bolt-failed-tuple! task-stats
src/clj/backtype/storm/daemon/task.clj:    (log-message "Preparing bolt " component-id ":" task-id)
src/clj/backtype/storm/daemon/task.clj:    (log-message "Prepared bolt " component-id ":" task-id)
src/clj/backtype/storm/daemon/task.clj:    [(mk-task-receiver receive-queue deserializer tuple-action-fn)]
src/clj/backtype/storm/daemon/task.clj:(defmethod mk-task-stats ISpout [_ rate]
src/clj/backtype/storm/daemon/task.clj:(defmethod mk-task-stats IBolt [_ rate]
src/clj/backtype/storm/daemon/worker.clj:(defn read-worker-task-ids [storm-cluster-state storm-id supervisor-id port]
src/clj/backtype/storm/daemon/worker.clj:  (let [assignment (:task->node+port (.assignment-info storm-cluster-state storm-id nil))]
src/clj/backtype/storm/daemon/worker.clj:      (mapcat (fn [[task-id loc]]
src/clj/backtype/storm/daemon/worker.clj:                [task-id]
src/clj/backtype/storm/daemon/worker.clj:(defnk do-task-heartbeats [worker :tasks nil]
src/clj/backtype/storm/daemon/worker.clj:                  (into {} (map (fn [t] {t nil}) (:task-ids worker)))
src/clj/backtype/storm/daemon/worker.clj:                    (map (fn [t] {(task/get-task-id t) (task/render-stats t)}))
src/clj/backtype/storm/daemon/worker.clj:               :task-stats stats
src/clj/backtype/storm/daemon/worker.clj:             (:task-ids worker)
src/clj/backtype/storm/daemon/worker.clj:      (:task->component worker)
src/clj/backtype/storm/daemon/worker.clj:      (vec (:task-ids worker)))))
src/clj/backtype/storm/daemon/worker.clj:  "Returns seq of task-ids that receive messages from this worker"
src/clj/backtype/storm/daemon/worker.clj:                     (fn [task-id]
src/clj/backtype/storm/daemon/worker.clj:                       (->> (system-topology-context worker task-id)
src/clj/backtype/storm/daemon/worker.clj:                     (:task-ids worker))]
src/clj/backtype/storm/daemon/worker.clj:        :task->component
src/clj/backtype/storm/daemon/worker.clj:        task-ids (set (read-worker-task-ids storm-cluster-state storm-id supervisor-id port))
src/clj/backtype/storm/daemon/worker.clj:        receive-queue-map (into {} (dofor [tid task-ids] [tid (LinkedBlockingQueue.)]))
src/clj/backtype/storm/daemon/worker.clj:             :task-ids task-ids
src/clj/backtype/storm/daemon/worker.clj:             :task->component (storm-task-info topology storm-conf)
src/clj/backtype/storm/daemon/worker.clj:             :task->node+port (atom {})
src/clj/backtype/storm/daemon/worker.clj:              my-assignment (select-keys (:task->node+port assignment) outbound-tasks)
src/clj/backtype/storm/daemon/worker.clj:                                      (filter-key (complement (:task-ids worker)))
src/clj/backtype/storm/daemon/worker.clj:                (reset! (:task->node+port worker) my-assignment))
src/clj/backtype/storm/daemon/worker.clj:          task->node+port @(:task->node+port worker)]
src/clj/backtype/storm/daemon/worker.clj:        (let [socket (node+port->socket (task->node+port task))]
src/clj/backtype/storm/daemon/worker.clj:        _ (do-task-heartbeats worker)
src/clj/backtype/storm/daemon/worker.clj:        tasks (dofor [tid (:task-ids worker)] (task/mk-task worker (system-topology-context worker tid) (user-topology-context worker tid)))
src/clj/backtype/storm/daemon/worker.clj:    (schedule-recurring (:timer worker) 0 (conf TASK-REFRESH-POLL-SECS) refresh-connections)
src/clj/backtype/storm/daemon/worker.clj:    (schedule-recurring (:timer worker) 0 (conf TASK-REFRESH-POLL-SECS) (partial refresh-storm-active worker))
src/clj/backtype/storm/daemon/worker.clj:    (schedule-recurring (:timer worker) 0 (conf TASK-HEARTBEAT-FREQUENCY-SECS) #(do-task-heartbeats worker :tasks tasks))
src/clj/backtype/storm/stats.clj:(defmacro update-task-stat! [stats path & args]
src/clj/backtype/storm/stats.clj:  (update-task-stat! stats [:common :emitted] stream (stats-rate stats)))
src/clj/backtype/storm/stats.clj:  (update-task-stat! stats [:common :transferred] stream (* (stats-rate stats) amt)))
src/clj/backtype/storm/stats.clj:    (update-task-stat! stats :acked key (stats-rate stats))
src/clj/backtype/storm/stats.clj:    (update-task-stat! stats :process-latencies key latency-ms)
src/clj/backtype/storm/stats.clj:    (update-task-stat! stats :failed key (stats-rate stats))
src/clj/backtype/storm/stats.clj:  (update-task-stat! stats :acked stream (stats-rate stats))
src/clj/backtype/storm/stats.clj:  (update-task-stat! stats :complete-latencies stream latency-ms)
src/clj/backtype/storm/stats.clj:  (update-task-stat! stats :failed stream (stats-rate stats))
src/clj/backtype/storm/stats.clj:(defn thriftify-task-stats [stats]
src/clj/backtype/storm/testing.clj:(defn submit-mocked-assignment [nimbus storm-name conf topology task->component task->node+port]
src/clj/backtype/storm/testing.clj:  (with-var-roots [common/storm-task-info (fn [& ignored] task->component)
src/clj/backtype/storm/testing.clj:                   nimbus/compute-new-task->node+port (fn [& ignored] task->node+port)]
src/clj/backtype/storm/testing.clj:                          (common/storm-task-info
src/clj/backtype/storm/testing.clj:        task-ids (apply concat (vals component->tasks))
src/clj/backtype/storm/testing.clj:        taskbeats (.taskbeats state storm-id (:task->node+port assignment))
src/clj/backtype/storm/testing.clj:        heartbeats (dofor [id task-ids] (get taskbeats id))
src/clj/backtype/storm/ui/core.clj:(defn task-summary-type [topology ^TaskSummary s]
src/clj/backtype/storm/ui/core.clj:  (= :spout (task-summary-type topology s)))
src/clj/backtype/storm/ui/core.clj:  (= :bolt (task-summary-type topology s)))
src/clj/backtype/storm/ui/core.clj:(defn component-task-summs [^TopologyInfo summ topology id]
src/clj/backtype/storm/ui/core.clj:(defn spout-task-table [topology-id tasks window include-sys?]
src/clj/backtype/storm/ui/core.clj:     (spout-task-table (.get_id topology-info) tasks window include-sys?)
src/clj/backtype/storm/ui/core.clj:(defn bolt-task-table [topology-id tasks window include-sys?]
src/clj/backtype/storm/ui/core.clj:     (bolt-task-table (.get_id topology-info) tasks window include-sys?)
src/clj/backtype/storm/ui/core.clj:          summs (component-task-summs summ topology component)
