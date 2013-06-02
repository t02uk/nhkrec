#!/usr/bin/ruby
require 'open-uri'
require 'kconv'
require 'setting.rb'



class Downloader
  def download
    file = self.get_name()
    stop = self.get_stop()
    directory = self.get_directory()
    cmd = %(rtmpdump --rtmp "rtmpe://netradio-fm-flash.nhk.jp" --playpath 'NetRadio_FM_flash@63343' --app "live" -W http://www3.nhk.or.jp/netradio/files/swf/rtmpe.swf --live --stop #{stop} -o /tmp/nhkrec.m4a)
    sleep 1 until Time.now.sec >= 58

    `#{cmd}`
    `mv /tmp/nhkrec.m4a #{directory}#{file}.m4a`

  end

  def downloadable?
    !!@title
  end
end

class Aoado < Downloader

  def initialize
    content = open("http://www.nhk.or.jp/audio/html_se/index.html").read
    content = content.split(/\n/).join("\n")
    idx = content.toutf8 =~ /((\d+)年(\d+)月(\d+)日～(\d+)月(\d+)日の放送は)?休止/
    if $1
      from = Time.mktime($2, $3, $4)
      to = Time.mktime($2, $5, $6)
      return if from <= Time.now && Time.now <= to
    end
    idx2 = content =~ /<a href="se\d+\.html">(.+?)<\/a>/
    @title = $1.toutf8
    @title = @title.gsub(/(『|』)/, '')
  end

  def get_name
    Dir::chdir(DIR_AOADO) {
      recent = Dir::glob("#{@title}_*.m4a").map{|file|
        file =~ /(\d+)\.m4a$/; $1
      }.sort.last
      new = "%02d" % (recent.to_i + 1)
      new = "#{@title}_#{new}"
    }
  end

  def get_stop
    15 * 60 + 5
  end

  def get_directory
    DIR_AOADO
  end
end

class FMTheater < Downloader

  def initialize
    content = open("http://www.nhk.or.jp/audio/html_fm/index.html").read
    content = content.split(/\n/).join("\n")
    idx = content.toutf8 =~ /休止/
    idx2 = content.toutf8 =~ /<a href="fm\d+\.html">(.+?)<\/a>/
    unless idx && idx < idx2
      @title = $1.toutf8
      @title = @title.gsub(/(『|』)/, '')
    end
  end

  def get_name
    @title
  end

  def get_stop
    60 * 60 + 5
  end

  def get_directory
    DIR_FMTHEATER
  end
end

downloader = eval("#{ARGV[0]}.new")
if downloader.downloadable?
  downloader.download
end
