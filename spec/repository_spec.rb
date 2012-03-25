require "spec_helper.rb"

describe Repository do
  let(:project_path) { "test/project" }
  let(:repository_dir) { File.join(project_path, Repository::REPOSITORY_DIR) }

  before do
    FileUtils.mkdir_p project_path

  end

  after do
    FileUtils.rm project_path, :force => true
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
    before do
      FileUtils.mkdir_p(File.join(project_path, Repository::REPOSITORY_DIR))
      FileUtils.mkdir_p("/dev/")
      FileUtils.touch(untracked)
      FileUtils.touch(DiffBase::NULL_FILE)
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

    it "should equals modified only array" do
      @repo.modified_files(:indexed).should == [modified]
    end

    it "should equals untracked only array" do
      @repo.new_files(:indexed).should == [untracked] 
    end

    it "should equals modified only array" do
      @repo.deleted_files(:indexed).should == [deleted] 
    end
  end
end
