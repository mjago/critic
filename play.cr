require "io/console"
require "colorize"

now = Time.now

# colors
#  :black,
#  :red,
#  :green,
#  :yellow,
#  :blue,
#  :magenta,
#  :cyan,
#  :light_gray,
#  :dark_gray,
#  :light_red,
#  :light_green,
#  :light_yellow,
#  :light_blue,
#  :light_magenta,
#  :light_cyan,
#  :white

# modes
#  :bold,
#  :bright,
#  :dim,
#  :underline,
#  :blink,
#  :reverse,
#  :hidden

class Prepare
  def self.clean(dirs : Array(String), chan : Channel(String))
    dirs.each do |dir|
      files = Dir.new(dir)
      files.each do |file|
        next if file == "." || file == ".."
#        FileUtils.rm_r(file) if file
        puts(file) if file
      end
    end
    chan.send("cleaned")
  end
end

class Unity

  def compile(file, ch : Channel)
    args = "-c "      +
           "-m64 "           +
           "-Wall "         +
           "-Wno-address "  +
           "-std=c99 "      +
           "-pedantic"

    system("clang #{file} #{args} -o Unity/build/#{File.basename(file)}.o")
    ch.send(false)
  end

  def link(file, ch : Channel)
    args = " -lm " +
           " -m64 "
#    puts system("clang -o runner #{args} Unity/build/unity.o")
    ch.send("linked #{file}")
  end
end

class Runner
  puts Time.now.to_s.colorize(:blue)

  ch = Channel(String).new
  spawn do
    clean = Prepare.clean(["Unity/build"], ch)
  end
  puts ch.receive.to_s

  chb1 = Channel(Bool).new
  chb2 = Channel(Bool).new
  u1 = Unity.new
  u2 = Unity.new
  500.times do
    spawn do
      print '.'.colorize(:green)
      u1.compile("Unity/examples/example_3/src/ProductionCode.c", chb1)
    end

    spawn do
#      u = Unity.new
      print '.'.colorize(:green)
      u2.compile("Unity/examples/example_3/src/ProductionCode2.c", chb2)
    end

    chb1.receive#.colorize(:magenta)
    chb2.receive#.colorize(:magenta)
  end

  spawn do
    u1 = Unity.new
    u1.link("runner", ch)
  end

  puts ch.receive.colorize(:magenta)
  ch.close
end

runner = Runner.new
puts "done"
puts(Time.now - now).to_s + " secs"
puts Time.now.to_s.colorize(:blue)

