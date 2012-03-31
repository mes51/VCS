class LogCommand < Command
  def self.command
    :log
  end

  def execute(args)
    @repo.commit_log.each do |l|
      print "commit " + l[:hash] + "\n"
      print "Date:" + l[:date].strftime("%Y/%m/%d %H:%M") + "\n"
      print l[:commit_message] + "\n\n"
    end
  end
end
