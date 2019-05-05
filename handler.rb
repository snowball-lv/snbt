
require "nokogiri"
require "open-uri"
require "uri"
require "json"
require "unicode"
require "i18n"
require "cinch"

TYPO_MSG = "Iespējams, ka vārds ir uzrakstīts kļūdaini. Piedāvājam šādus rezultātus:"

def get_spelling(word, unknown, misspellings)

    # normalize word to lower case
    word = Unicode.downcase(word)
    
    # check for word in unknown set
    if unknown.include?(word)
        puts "--- FOUND WORD IN UNKNOWN SET"
        return word
    end

    # check for word in misspelling map
    if misspellings.has_key?(word)
        puts "--- FOUND WORD IN MISSPELLING MAP"
        return misspellings[word]
    end

    puts "--- FETCHING DEFINITION FROM NETWORK"

    url = "https://www.letonika.lv/groups/default.aspx?q=#{word}&s=0&g=5&r=1100"
    puts URI.escape(url)
    doc = Nokogiri::HTML(open(URI.escape(url)))
    
    # wait for the sake of politeness
    sleep 1

    elem = doc.at_xpath("//p[1]")
    if elem.text.strip == TYPO_MSG
        puts "--- TYPO"
        suggestion = doc.at_xpath("//p[2]/b/a/text()")
        if suggestion

            suggestion = suggestion.text.strip

            puts "--- SUGGESTION: #{suggestion}"
            suggestion = Unicode.downcase(suggestion)

            if word != suggestion
                if I18n.transliterate(word) == I18n.transliterate(suggestion)

                    puts "--- SUGGESTION ACCEPTED"
                    misspellings[word] = suggestion
                    # File.write("misspellings.json", JSON.pretty_generate(misspellings))
                    return suggestion

                end
            end
            
            puts "--- SUGGESTION DISCARDED"
        else
            puts "NO SUGGESTIONS"
        end
    else
        puts "NO TYPO"
    end

    unknown.push(word)
    # File.write("unknown.json", JSON.pretty_generate(unknown))
    return word
end

def get_ignored_users()
    if File.file?("ignored-users.json")
        return JSON.parse(File.read("ignored-users.json")) 
    end
    return []
end

def set_ignored_users(arr)
    File.write("ignored-users.json", JSON.pretty_generate(arr))
end

def get_ignored_words()
    if File.file?("ignored-words.json")
        return JSON.parse(File.read("ignored-words.json")) 
    end
    return []
end

def set_ignored_words(arr)
    File.write("ignored-words.json", JSON.pretty_generate(arr))
end

# LOG_CHANNELS = [ "#snowball-estate", "#meeseekeria", "#develoeprslv" ]

def cmd_dummy(m, cmd, args)
    m.reply("#{cmd.join(' ')}")
end

def cmd_commands(m, cmd, args)
    m.reply(COMMANDS.keys
        .map { |k| "\"#{k.join(" ")}\""}
        .join(" "))
end

def cmd_ignore_users(m, cmd, args)
    ignored = get_ignored_users
    args.each do |u|
        unless ignored.include?(u)
            ignored.push(u)
        end
    end
    set_ignored_users(ignored)
    # if LOG_CHANNELS.include?(m.channel.to_s)
        m.reply("Ok, ignoring users: #{args.join(' ')}")
    # end
end

def cmd_unignore_users(m, cmd, args)
    ignored = get_ignored_users
    args.each do |u|
        if ignored.include?(u)
            ignored.delete(u)
        end
    end
    set_ignored_users(ignored)
    # if LOG_CHANNELS.include?(m.channel.to_s)
        m.reply("Ok, unignoring users: #{args.join(' ')}")
    # end
end

def cmd_ignored_users(m, cmd, args)
    ignored = get_ignored_users
    m.reply("Ignoring users: #{ignored.join(' ')}")
end

def cmd_ignore_words(m, cmd, args)
    ignored = get_ignored_words
    args.each do |w|
        unless ignored.include?(w)
            ignored.push(w)
        end
    end
    set_ignored_words(ignored)
    # if LOG_CHANNELS.include?(m.channel.to_s)
        m.reply("Ok, ignoring words: #{args.join(' ')}")
    # end
end

def cmd_unignore_words(m, cmd, args)
    ignored = get_ignored_words
    args.each do |w|
        if ignored.include?(w)
            ignored.delete(w)
        end
    end
    set_ignored_words(ignored)
    # if LOG_CHANNELS.include?(m.channel.to_s)
        m.reply("Ok, unignoring words: #{args.join(' ')}")
    # end
end

def cmd_ignored_words(m, cmd, args)
    ignored = get_ignored_words
    m.reply("Ignoring words: #{ignored.join(' ')}")
end

def cmd_quit(m, cmd, args)
    m.bot.quit
end

def devlv_cmd_ping(m, rem)
    m.reply("pong")
end

def devlv_cmd_echo(m, rem)
    if !rem.strip.empty?
        m.reply(rem.strip)
    end
end

def devlv_cmd_version(m, rem)
    m.reply("1.1.0 https://github.com/snowball-lv/snbt")
end

START_TIME = Time.now.to_i

def devlv_cmd_uptime(m, rem)
    delta = Time.now.to_i - START_TIME
    uptime = []

    secs = delta
    if secs % 60 > 0; uptime.push("#{secs % 60}s"); end

    mins = secs / 60;
    if mins % 60 > 0; uptime.push("#{mins % 60}m"); end

    hours = mins / 60;
    if hours % 24 > 0; uptime.push("#{hours % 24}h"); end

    days = hours / 24;
    if days % 365 > 0; uptime.push("#{days % 365}h"); end

    years = days / 365;
    if years > 0; uptime.push("#{years}y"); end

    if uptime.empty?
        m.reply("0s")
    else
        m.reply(uptime.reverse.join(" "))
    end
end

COMMANDS = {

    [ "ignore", "users", "..." ]    => method(:cmd_ignore_users),
    [ "unignore", "users", "..." ]  => method(:cmd_unignore_users),
    [ "ignored", "users" ]          => method(:cmd_ignored_users),

    [ "ignore", "words", "..." ]    => method(:cmd_ignore_words),
    [ "unignore", "words", "..." ]  => method(:cmd_unignore_words),
    [ "ignored", "words" ]          => method(:cmd_ignored_words),

    [ "commands" ]                  => method(:cmd_commands),

    # [ "quit" ] => method(:cmd_quit),
}

DEVLV_CMDS = {
    "ping"      => method(:devlv_cmd_ping),
    "echo"      => method(:devlv_cmd_echo),
    "version"   => method(:devlv_cmd_version),
    "uptime"    => method(:devlv_cmd_uptime),
}

CMDS = DEVLV_CMDS.keys.join("|")

def process_devlv_cmds(m)
    
    our_nick = m.bot.nick
    
    msg = m.message
    cmd = nil
    rem = nil

    if mch = /^[!,](#{CMDS})(.*)/.match(msg.strip)
        cmd = mch[1]
        rem = mch[2]
    elsif mch = /^(\w+)\s*[,:]\s*(#{CMDS})(.*)/.match(msg.strip)
        nick = mch[1]
        if nick.downcase == our_nick.downcase
            cmd = mch[2]
            rem = mch[3]
        end
    end
    
    if cmd
        DEVLV_CMDS[cmd].call(m, rem)
        return true
    end

    return false
end

def handle(m)

    I18n.config.available_locales = [:en, :lv]

    if process_devlv_cmds(m)
        return
    end

    text = m.message
    text = Cinch::Formatting.unformat(text)
    text = Unicode.downcase(text)
    words = text.scan(/[[:word:]]+/)

    our_nick = m.bot.nick.downcase

    COMMANDS.each do |cmd, handler|
        full = [ our_nick ] + cmd
        full.pop if full.last == "..."
        if full == words.first(full.size)
            handler.call(m, cmd, words.drop(full.size))
            return
        end
    end

    if get_ignored_users.include?(m.user.nick.downcase)
        puts "IGNORING USER #{m.user.nick}"
        return
    end

    get_ignored_words.each do |i|
        if words.include?(i)
            puts "IGNORING WORD #{i}"
            words.delete(i)
        end
    end

    unless File.file?("unknown.json")
        File.write("unknown.json", "[]")
    end
    unknown = JSON.parse(File.read("unknown.json"))

    unless File.file?("misspellings.json")
        File.write("misspellings.json", "{}")
    end
    misspellings = JSON.parse(File.read("misspellings.json"))

    words.each do |w|

		if w.size < 6
			next
		end
    
        correction = get_spelling(w, unknown, misspellings)
        unless Unicode.strcmp(Unicode.downcase(w), correction) == 0

            # 10% chance
            if rand(100) < 10

                m.reply("#{m.user.nick}, nevis \"#{w}\", bet \"#{correction}\"")
                Channel('#snowball-estate')
                    .send("#{m.user.nick}, nevis \"#{w}\", bet \"#{correction}\"")
                break

            end
        end
    end

    File.write("misspellings.json", JSON.pretty_generate(misspellings))
    File.write("unknown.json", JSON.pretty_generate(unknown))

end
