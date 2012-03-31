class ResetCommand < Command
  def self.command
    :reset
  end

  def execute(args)
    mode = :soft
    if args.length > 1 && args[0] == "--hard"
      mode = :hard
      args.shift
    end

    if args[0].index("HEAD") == 0
      s = args[0].slice(4, args[0].length)
      count = 0
      if s[0] == "~"
        count = s.slice(1, s.length).to_i
      else
        while s[count] == "^"
          count += 1
        end
      end

      begin
        @repo.reset_by_count count, mode
      rescue ArgumentError
        print "invalid count\n"
      end
    end
  end
end
