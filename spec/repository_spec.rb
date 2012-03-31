require "spec_helper.rb"

describe Repository do
  let(:project_path) { "test/project" }
  let(:repository_dir) { File.join(project_path, Repository::REPOSITORY_DIR) }

  before do
    FileUtils.mkdir_p project_path
  end

  after do
    FileUtils.rm_r project_path, :force => true
  end

  context "#create_repository" do
    context "not found repository dir" do
      it "should exists repository_dir" do
        Repository.new(project_path).create_repository(false)
        Dir.exists?(repository_dir).should be_true
      end

      it "should empty repository dir" do
        Repository.new(project_path).create_repository(false)
        Dir.glob(File.join(repository_dir, "*")).should == []
      end
    end

    context "already exists repository dir" do
      before do
        FileUtils.mkdir_p repository_dir
        FileUtils.touch(File.join(repository_dir, "index"))
        @repo = Repository.new(project_path)
      end

      context "not force oprion give" do
        specify { expect { @repo.create_repository(false) }.to raise_error(RuntimeError) }
      end

      context "force oprion given" do
        it "should empty repository dir" do
          @repo.create_repository(true)
          Dir.glob(File.join(repository_dir, "*")).should == []
        end
      end
    end
  end

  context "file status methods" do
    let(:tracked) { File.expand_path(File.join(project_path, "tracked.txt")) }
    let(:untracked) { File.expand_path(File.join(project_path, "untracked.txt")) }
    let(:modified) { File.expand_path(File.join(project_path, "modified.txt")) }
    let(:deleted) { File.expand_path(File.join(project_path, "deleted.txt")) }
    let(:indexing_untracked) { File.expand_path(File.join(project_path, "indexing_untracked.txt")) }
    let(:indexing_modified) { File.expand_path(File.join(project_path, "indexing_modified.txt")) }
    let(:indexing_deleted) { File.expand_path(File.join(project_path, "indexing_deleted.txt")) }
    let(:modify_after_indexing_untracked) { File.expand_path(File.join(project_path, "modify_after_indexing_untracked.txt")) }
    let(:modify_after_indexing_modified) { File.expand_path(File.join(project_path, "modify_after_indexing_modified.txt")) }
    let(:create_after_indexing_deleted) { File.expand_path(File.join(project_path, "create_after_indexing_deleted.txt")) }
    let(:delete_after_indexing_untracked) { File.expand_path(File.join(project_path, "delete_after_indexing_untracked.txt")) }
    let(:text) { "text" }
    let(:changed) { "changed" }
    let(:more_changed) { "more changed" }
    let(:text_hash) { Digest::SHA1.digest(text) }
    let(:changed_hash) { Digest::SHA1.digest(changed) }
    let(:more_changed_hash) { Digest::SHA1.digest(more_changed) }
    before do
      FileUtils.mkdir_p(File.join(project_path, Repository::REPOSITORY_DIR))
      FileUtils.touch(untracked)
      File.open(tracked, "w+") { |f| f.write(text) }
      File.open(modified, "w+") { |f| f.write(changed) }
      File.open(indexing_untracked, "w+") { |f| f.write(text) }
      File.open(indexing_modified, "w+") { |f| f.write(changed) }
      File.open(modify_after_indexing_modified, "w+") { |f| f.write(more_changed) }
      File.open(modify_after_indexing_untracked, "w+") { |f| f.write(changed) }
      File.open(create_after_indexing_deleted, "w+") { |f| f.write(text) }

      index = Index.new(project_path)
      index.indexed_file_hash = {
        tracked => text_hash,
        modified => text_hash,
        deleted => text_hash,
        indexing_untracked => text_hash,
        indexing_modified => changed_hash,
        modify_after_indexing_untracked => text_hash,
        modify_after_indexing_modified => changed_hash,
        delete_after_indexing_untracked => text_hash,
      }
      index.data = {
        tracked => text,
        modified => text,
        deleted => text,
        indexing_modified => text,
        indexing_deleted => text,
        modify_after_indexing_modified => text,
        create_after_indexing_deleted => text,
      }
      index.hunks = [
        Hunk.new(indexing_untracked, { add: text, delete: nil }, :create, :DiffBase),
        Hunk.new(indexing_modified, { add: changed, delete: text }, :change, :DiffBase),
        Hunk.new(indexing_deleted, { add: nil, delete: text }, :remove, :DiffBase),
        Hunk.new(modify_after_indexing_untracked, { add: text, delete: nil }, :create, :DiffBase),
        Hunk.new(modify_after_indexing_modified, { add: changed, delete: text }, :change, :DiffBase),
        Hunk.new(create_after_indexing_deleted, { add: nil, delete: text }, :remove, :DiffBase),
        Hunk.new(delete_after_indexing_untracked, { add: text, delete: nil }, :create, :DiffBase),
      ]
      index.save_index
      @repo = Repository.new(project_path)
    end

    context "#new_files" do
      context ":all given" do
        subject { @repo.new_files(:all) }
        it { should == [create_after_indexing_deleted, indexing_untracked, modify_after_indexing_untracked, untracked, delete_after_indexing_untracked] }
      end

      context ":not_indexed given" do
        subject { @repo.new_files(:not_indexed) }
        it { should == [create_after_indexing_deleted, untracked] }
      end

      context ":indexed given" do
        subject { @repo.new_files(:indexed) }
        it { should == [indexing_untracked, modify_after_indexing_untracked, delete_after_indexing_untracked] }
      end
    end

    context "#modified_files" do
      context ":all given" do
        subject { @repo.modified_files(:all) }
        it { should == [indexing_modified, modified, modify_after_indexing_modified, modify_after_indexing_untracked] }
      end

      context ":not_indexed given" do
        subject { @repo.modified_files(:not_indexed) }
        it { should == [modified, modify_after_indexing_modified, modify_after_indexing_untracked] }
      end

      context ":indexed given" do
        subject { @repo.modified_files(:indexed) }
        it { should == [indexing_modified, modify_after_indexing_modified] }
      end
    end

    context "#deleted_files" do
      context ":all given" do
        subject { @repo.deleted_files(:all) }
        it { should == [deleted, indexing_deleted, delete_after_indexing_untracked] }
      end

      context ":not_indexed given" do
        subject { @repo.deleted_files(:not_indexed) }
        it { should == [deleted, delete_after_indexing_untracked] }
      end

      context ":indexed given" do
        subject { @repo.deleted_files(:indexed) }
        it { should == [indexing_deleted] }
      end
    end

    context "#all_changed_files" do
      subject { @repo.all_changed_files }
      it { should == [indexing_modified, indexing_untracked, modified, modify_after_indexing_modified, modify_after_indexing_untracked, untracked, deleted, indexing_deleted] }
    end
  end

  context "#indexing" do
    let(:tracked) { File.expand_path(File.join(project_path, "tracked.txt")) }
    let(:untracked) { File.expand_path(File.join(project_path, "untracked.txt")) }
    let(:modified) { File.expand_path(File.join(project_path, "modified.txt")) }
    let(:deleted) { File.expand_path(File.join(project_path, "deleted.txt")) }
    let(:text) { "text" }
    let(:changed) { "changed" }
    let(:text_hash) { Digest::SHA1.digest(text) }
    let(:changed_hash) { Digest::SHA1.digest(changed) }
    let(:hash_expected) do
      { modified => changed_hash, tracked => text_hash, untracked => text_hash }
    end
    before do
      FileUtils.mkdir_p(File.join(project_path, Repository::REPOSITORY_DIR))
      FileUtils.mkdir_p("/dev/")
      FileUtils.touch(DiffBase::NULL_FILE)
      File.open(untracked, "w+") { |f| f.write(text) }
      File.open(tracked, "w+") { |f| f.write(text) }
      File.open(modified, "w+") { |f| f.write(changed) }

      index = Index.new(project_path)
      index.indexed_file_hash = {
        tracked => text_hash,
        modified => text_hash,
        deleted => text_hash,
      }
      index.data = {
        tracked => text,
        modified => text,
        deleted => text,
      }
      index.save_index
      @repo = Repository.new(project_path)
      @repo.indexing([deleted, modified, tracked, untracked])
    end

    after do
      FileUtils.rm(DiffBase::NULL_FILE)
    end

    subject { Index.new(project_path) }
    its(:hunks) { subject.length.should == 3 }
    its(:indexed_file_hash) { should == hash_expected }
  end

  context "#commit" do
    let(:modified) { File.expand_path(File.join(project_path, "modified.txt")) }
    let(:text) { "text" }
    let(:text_hash) { Digest::SHA1.digest(text) }
    before do
      FileUtils.mkdir_p(File.join(project_path, Repository::REPOSITORY_DIR))
      stub(Time).now { Time.new(2012, 3, 26, 12, 30) }
    end

    context "empty indexed hunks" do
      before do
        @repo = Repository.new project_path
        @repo.commit "first commit"
      end

      it "not exists .vcs/commits" do
        File.exists?(File.join(project_path, Repository::REPOSITORY_DIR, "commits")).should be_false
      end
    end

    context "exists indexet hunks" do
      before do
        index = Index.new project_path
        index.indexed_file_hash = { modified => text_hash }
        index.hunks = [Hunk.new(modified, { add: text, delete: nil }, :create, :DiffBase)]
        index.save_index
        @repo = Repository.new project_path
        @repo.commit "first commit"
      end

      it "should saved commit array into .vcs/commits" do
        Marshal.load(File.open(File.join(project_path, Repository::REPOSITORY_DIR, "commits")).read).length.should == 1
      end

      it "should be nil indexed hunk" do
        Index.new(project_path).hunks.should be_nil
      end

      it "should equals hash" do
        Digest::SHA1.digest(Index.new(project_path).data[modified]).should == text_hash
      end
    end
  end

  context "#commit_log" do
    context "not commited repository" do
      before do
        @repo = Repository.new project_path
      end

      subject { @repo.commit_log }
      it { should == [] }
    end

    context "some commited repository" do
      let(:file) { File.expand_path(File.join(project_path, "file.txt")) }
      let(:text) { "text" }
      let(:changed_hash) { Digest::SHA1.digest(changed) }
      let(:first_commit) { "first commit" }
      let(:delete_file) { "delete file" }
      let(:time) { Time.new(2012, 3, 27) }
      let(:expected) {
        [
          {
            hash: "93fc6951b7fb0a440416435d0ae4fca0a654f30c",
            date: time,
            commit_message: first_commit
          },
          {
            hash: "fc5ad68c2a7efff57512155d96f6cf442086b95c",
            date: time,
            commit_message: delete_file
          }
        ]
      }
      before do
        stub(Time).now { time }
        commits = [
          Commit.new([Hunk.new(file, { add: text, delete: nil }, :create, :DiffBase)], "first commit"),
          Commit.new([Hunk.new(file, { add: nil, delete: text }, :remove, :DiffBase)], "delete file")
        ]
        FileUtils.mkdir_p(File.join(project_path, Repository::REPOSITORY_DIR))
        File.open(File.join(project_path, Repository::REPOSITORY_DIR, "commits"), "w+") do |f|
          f.write(Marshal.dump(commits))
        end
        @repo = Repository.new project_path
      end

      subject { @repo.commit_log }
      it { should == expected }
    end
  end

  context "reset methods" do
    let(:file) { File.expand_path(File.join(project_path, "file.txt")) }
    let(:tracked) { File.expand_path(File.join(project_path, "tracked.txt")) }
    let(:untracked) { File.expand_path(File.join(project_path, "untracked.txt")) }
    let(:text) { "text" }
    let(:changed) { "changed" }
    let(:text_hash) { Digest::SHA1.digest(text) }
    let(:changed_hash) { Digest::SHA1.digest(changed) }
    let(:first_commit) { "first commit" }
    let(:delete_file) { "delete file" }
    let(:create_file) { "create file" }
    let(:time) { Time.new(2012, 3, 27) }
    let(:commits) do
      [
        Commit.new([Hunk.new(file, { add: text, delete: nil }, :create, :DiffBase)], first_commit),
        Commit.new([Hunk.new(file, { add: nil, delete: text }, :remove, :DiffBase)], delete_file),
        Commit.new([Hunk.new(tracked, { add: text, delete: nil }, :create, :DiffBase)], create_file),
      ]
    end
    before do
      stub(Time).now { time }
      FileUtils.mkdir_p(File.join(project_path, Repository::REPOSITORY_DIR))
      File.open(untracked, "w+") { |f| f.write(text) }
      File.open(tracked, "w+") { |f| f.write(changed) }
      File.open(File.join(project_path, Repository::REPOSITORY_DIR, "commits"), "w+") do |f|
        f.write(Marshal.dump(commits))
      end
      index = Index.new project_path
      index.hunks = [
        Hunk.new(tracked, { add: changed, delete: text }, :change, :DiffBase),
        Hunk.new(untracked, { add: text, delete: nil }, :create, :DiffBase)
      ]
      index.indexed_file_hash = {
        tracked => changed_hash,
        untracked => text_hash
      }
      index.data = { tracked => text }
      index.save_index
      @repo = Repository.new project_path
    end

    context "#reset_by_count" do
      context "negative number given" do
        let(:count) { -1 }
        specify { expect { @repo.reset_by_count(count, :hard) }.to raise_error(ArgumentError) }
      end

      context "bigger than all commits count given" do
        let(:count) { 1000 }
        specify { expect { @repo.reset_by_count(count, :hard) }.to raise_error(ArgumentError) }
      end

      context "0 given" do
        let(:count) { 0 }
        context ":hard given" do
          let(:mode) { :hard }
          before do
            @repo.reset_by_count count, mode
            @index = Index.new project_path
          end
          
          it "tracked file should equals before edit file" do
            Digest::SHA1.digest(File.open(tracked).read).should == text_hash            
          end

          it "indexed file hash should equals data digests" do
            @index.indexed_file_hash.all? { |k, v| v == Digest::SHA1.digest(@index.data[k]) }.should be_true
          end
        end

        context ":soft given" do
          let(:mode) { :soft }
          before do
            @repo.reset_by_count count, mode
            @index = Index.new project_path
          end

          it "tracked file should not change" do
            Digest::SHA1.digest(File.open(tracked).read).should == changed_hash
          end

          it "indexed file hash should equals data digests" do
            @index.indexed_file_hash.all? { |k, v| v == Digest::SHA1.digest(@index.data[k]) }.should be_true
          end
        end
      end

      context "1 given" do
        let(:count) { 1 }
        context ":hard given" do
          let(:mode) { :hard }
          before do
            @repo.reset_by_count count, mode
            @index = Index.new project_path
          end
        end

        context ":soft given" do
          let(:mode) { :soft }
          before do
            @repo.reset_by_count count, mode
            @index = Index.new project_path
          end

          it "tracking file is empty" do
            @index.indexed_file_hash.should == {}
          end

          it "tracked file should not change" do
            Digest::SHA1.digest(File.open(tracked).read).should == changed_hash
          end
        end

        context ":hard given" do
          let(:mode) { :hard }
          before do
            @repo.reset_by_count count, mode
            @index = Index.new project_path
          end

          it "tracking file is empty" do
            @index.indexed_file_hash.should == {}
          end

          it "should delete tracked file" do
            File.exists?(tracked).should be_false
          end
        end
      end
    end
  end
end
