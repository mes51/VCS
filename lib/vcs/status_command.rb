class StatusCommand < Command
  def self.command
    :status
  end

  def execute(args)
    print "indexed---------------------------------------\n"
    print "new file:\n"
    @repo.new_files(:indexed).each { |f| print f + "\n" }

    print "\nmodified:\n"
    @repo.modified_files(:indexed).each { |f| print f + "\n" }

    print "\ndeleted:\n"
    @repo.deleted_files(:indexed).each { |f| print f + "\n" }

    print "not indexed-----------------------------------\n"
    print "new file:\n"
    @repo.new_files(:not_indexed).each { |f| print f + "\n" }

    print "\nmodified:\n"
    @repo.modified_files(:not_indexed).each { |f| print f + "\n" }

    print "\ndeleted:\n"
    @repo.deleted_files(:not_indexed).each { |f| print f + "\n" }
  end
end
