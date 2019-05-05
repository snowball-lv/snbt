#!/usr/bin/env ruby

require "json"
require "cinch"
require_relative "handler"

CONF = JSON.parse(File.read("conf.json"))

bot = Cinch::Bot.new do
    
    configure do |c|

        c.server = CONF["server"]
        c.port = CONF["port"]
        c.user = CONF["user"]
        c.password = CONF["password"]

        c.ssl.use = true

        c.sasl.username = CONF["user"]
        c.sasl.password = CONF["password"]
    end

    on :message do |m|
        begin
            handle(m)
        rescue StandardError => e
            puts e
        end
    end
end

bot.start
