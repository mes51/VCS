require "spec_helper.rb"

describe Commit do
  context "#initialize" do
    context "nil given" do
      specify { expect { Commit.new(nil) }.to raise_error(ArgumentError) }
    end

    context "not hunk array given" do
      context "int array given" do
        specify { expect { Commit.new([1, 2, 3, 4, 5]) }.to raise_error(ArgumentError) }
      end

      context "int given" do
        specify { expect { Commit.new(100) }.to raise_error(ArgumentError) }
      end
    end

    context "hunk array given" do
      let(:hunks) do
        [].tap do |a|
          10.times do |i|
            a << Hunk.new("/dev/" + i.to_s, i, :create, DiffBase)
          end
        end
      end
      let(:commit_msg) { "test commit" }

      before do
        stub(Time).now { Time.new(2012, 3, 24) }
      end

      subject { Commit.new(hunks, commit_msg) }
      its(:hash){ should == "f11d3dd12ccb4dae4f0ad324b4c58373fc928a27" }
      its(:hunks) { should == hunks }
      its(:commit_message) { should == commit_msg }
    end
  end
end
