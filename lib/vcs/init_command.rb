class InitCommand < Command
  def self.command
    :init
  end

  def execute(args)
    force = args.length > 0 && args[0] == "--force"
    begin
      @repo.create_repository force
    rescue
      print "Aready exists repository\n"
    end
  end
end
