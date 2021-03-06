module.exports = (env) ->

  Promise = env.require 'bluebird'

  class MqttSwitch extends env.devices.PowerSwitch

    constructor: (@config, @plugin, lastState) ->
      @name = config.name
      @id = config.id
      @_state = lastState?.state?.value or off
      @_dimlevel = lastState?.dimlevel?.value or 0


      if @plugin.connected
        @onConnect()

      @plugin.mqttclient.on('connect', =>
        @onConnect()
      )

      @plugin.mqttclient.on('message', (topic, message) =>
        if (@config.stateTopic == "" && @config.topic == topic) || (@config.stateTopic != "" && @config.stateTopic == topic)
          switch message.toString()
            when "on", "true", "1", "t", "o", "1.00"
              @_setState(on)
              @_state = on
              @emit "state", on
            else
              @_setState(off)
              @_state = off
              @emit "state", off
      )
      super()

    onConnect: () ->
      if @config.stateTopic == ""
        @plugin.mqttclient.subscribe(@config.topic)
      else
        @plugin.mqttclient.subscribe(@config.stateTopic)

    changeStateTo: (state) ->
      message = (if state then @config.onMessage else @config.offMessage)
      @plugin.mqttclient.publish(@config.topic, message)
      @_setState(state)
      return