module God
  module Conditions

    # Condition Symbol :flapping
    # Type: Trigger
    #
    # Trigger when a Task transitions to or from a state or states a given number
    # of times within a given period.
    #
    # Paramaters
    #   Required
    #     +times+ is the number of times that the Task must transition before
    #             triggering.
    #     +within+ is the number of seconds within which the Task must transition
    #              the specified number of times before triggering. You may use
    #              the sugar methods #seconds, #minutes, #hours, #days to clarify
    #              your code (see examples).
    #     --one or both of--
    #     +from_state+ is the state (as a Symbol) from which the transition must occur.
    #     +to_state is the state (as a Symbol) to which the transition must occur.
    #
    #   Optional:
    #     +retry_in+ is the number of seconds after which to re-monitor the Task after
    #                it has been disabled by the condition.
    #     +retry_times+ is the number of times after which to permanently unmonitor
    #                   the Task.
    #     +retry_within+ is the number of seconds within which
    #
    # Examples
    #
    # Trigger if
    class Flapping < TriggerCondition
      attr_accessor :times,
                    :within,
                    :from_state,
                    :to_state,
                    :action,
                    :between_actions

      def initialize
        @last_action = Time.at(0)
        self.info = "process is flapping"
      end

      def prepare
        @timeline = Timeline.new(self.times)
        @retry_timeline = Timeline.new(self.retry_times)
      end

      def valid?
        valid = true
        valid &= complain("Attribute 'times' must be specified", self) if self.times.nil?
        valid &= complain("Attribute 'within' must be specified", self) if self.within.nil?
        valid &= complain("Attributes 'from_state', 'to_state', or both must be specified", self) if self.from_state.nil? && self.to_state.nil?
        valid &= complain("Attribute 'action' must be specified", self) if self.action.nil?
        valid
      end

      def process(event, payload)
        begin
          if event == :state_change
            event_from_state, event_to_state = *payload

            from_state_match = !self.from_state || self.from_state && Array(self.from_state).include?(event_from_state)
            to_state_match = !self.to_state || self.to_state && Array(self.to_state).include?(event_to_state)

            if from_state_match && to_state_match
              @timeline << Time.now

              consensus = (@timeline.size == self.times)
              duration = (@timeline.last - @timeline.first) < self.within

              if consensus && duration
                @timeline.clear
                if @between_actions.nil? or (Time.now - @last_action > @between_actions)
                  @action.call
                  @last_action = Time.now
                end
              end
            end
          end
        rescue => e
          puts e.message
          puts e.backtrace.join("\n")
        end
      end

    end

  end
end
