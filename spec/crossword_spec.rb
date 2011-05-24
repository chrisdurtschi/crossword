require File.expand_path('../spec_helper', __FILE__)

describe Crossword::Solver do
  describe ".new" do
    it "takes slot positions and words" do
      solver = Crossword::Solver.new(
        [[1, 1, :down], [5, 5, :across]],
        %w[hello world today]
      )
      solver.instance_variable_get(:@slots).
        should == [[1, 1, :down], [5, 5, :across]]
      solver.instance_variable_get(:@words).
        should == %w[hello world today]
    end

    it "raises an exception if slots and words are unbalanced" do
      expect { Crossword::Solver.new(
        [[1, 1, :down], [5, 5, :across]],
        %w[hello world]
      ) }.to raise_error("must have 1 more word than slots")
      expect { Crossword::Solver.new(
        [[1, 1, :down], [5, 5, :across]],
        %w[hello world extra words]
      ) }.to raise_error("must have 1 more word than slots")
    end

    it "raises an exception if any word is longer than 10 letters" do
      expect { Crossword::Solver.new(
        [[1, 1, :down], [5, 5, :across]],
        %w[hello world hippopotamus]
      ) }.to raise_error("hippopotamus is more than 10 letters, dipshit")
    end
  end

  describe "#solve!" do
    it "solves a simple case" do
      solver = Crossword::Solver.new(
        [[1, 1, :down], [3, 1, :across]],
        %w[hello ladies gentlemen]
      )
      solver.solve!
      solver.solutions.map(&:grid).should == [[
        %w[h * * * * * * * * *],
        %w[e * * * * * * * * *],
        %w[l a d i e s * * * *],
        %w[l * * * * * * * * *],
        %w[o * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *]
      ]]
      solver.extra_words.should == %w[gentlemen]
    end

    it "solves a more complicated case" do
      solver = Crossword::Solver.new(
        [[1, 1, :down], [2, 3, :down], [3, 1, :across], [5, 2, :across]],
        %w[SLOW AGAIN BOY TAIL BEAR]
      )
      solver.solve!
      solver.solutions.map(&:grid).should == [[
        %w[B * * * * * * * * *],
        %w[E * T * * * * * * *],
        %w[A G A I N * * * * *],
        %w[R * I * * * * * * *],
        %w[* S L O W * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *]
      ]]
      solver.extra_words.should == %w[BOY]
    end

    it "cannot solve impossible cases" do
      solver = Crossword::Solver.new(
        [[1, 1, :down], [3, 1, :across], [1, 10, :down]],
        %w[HELLO THERE LADIES GENTLEMEN]
      )
      solver.solve!
      solver.solutions.map(&:grid).should == []
      solver.extra_words.should == []
    end

    it "solves cases with multiple solutions" do
            solver = Crossword::Solver.new(
        [[1, 1, :down], [2, 3, :down], [3, 1, :across], [5, 2, :across]],
        %w[SLOW AGAIN MAIL TAIL BEAR]
      )
      solver.solve!
      solver.solutions.map(&:grid).should == [[
        %w[B * * * * * * * * *],
        %w[E * T * * * * * * *],
        %w[A G A I N * * * * *],
        %w[R * I * * * * * * *],
        %w[* S L O W * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *]
      ],[
        %w[B * * * * * * * * *],
        %w[E * M * * * * * * *],
        %w[A G A I N * * * * *],
        %w[R * I * * * * * * *],
        %w[* S L O W * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *]
      ]]
      solver.extra_words.should == %w[MAIL TAIL]
    end
  end
end

describe Crossword::Board do
  describe ".new" do
    it "creates a grid from the placements" do
      board = Crossword::Board.new(
        Crossword::Placement.new("hello", 1, 1, :down),
        Crossword::Placement.new("ladies", 3, 1, :across)
      )

      board.instance_variable_get(:@grid).should == [
        %w[h * * * * * * * * *],
        %w[e * * * * * * * * *],
        %w[l a d i e s * * * *],
        %w[l * * * * * * * * *],
        %w[o * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *],
        %w[* * * * * * * * * *],
      ]
    end
  end

  describe "#valid?" do
    it "is true if all placements intersect correctly" do
      board = Crossword::Board.new(
        Crossword::Placement.new("hello", 1, 1, :down),
        Crossword::Placement.new("ladies", 3, 1, :across),
        Crossword::Placement.new("gentlemen", 2, 5, :down)
      )
      board.should be_valid
    end

    it "is false if there is a placement that does not intersect another placement" do
      board = Crossword::Board.new(
        Crossword::Placement.new("hello", 1, 1, :down),
        Crossword::Placement.new("ladies", 3, 1, :across),
        Crossword::Placement.new("gentlemen", 1, 10, :down)
      )
      board.should_not be_valid
    end

    it "is false if there is an invalid intersection" do
      board = Crossword::Board.new(
        Crossword::Placement.new("hello", 1, 1, :down),
        Crossword::Placement.new("ladies", 2, 1, :across)
      )
      board.should_not be_valid
    end

    it "is true for complex intersections" do
      board = Crossword::Board.new(
        Crossword::Placement.new("BEAR", 1, 1, :down),
        Crossword::Placement.new("AGAIN", 3, 1, :across),
        Crossword::Placement.new("TAIL", 2, 3, :down),
        Crossword::Placement.new("SLOW", 5, 2, :across)
      )
      board.should be_valid
    end
  end
end

describe Crossword::Placement do
  describe ".new" do
    it "takes a word, row, column, and direction" do
      placement = Crossword::Placement.new("hello", 2, 3, :down)
      placement.instance_variable_get(:@word).should  == "hello"
      placement.instance_variable_get(:@row).should   == 2
      placement.instance_variable_get(:@col).should   == 3
      placement.instance_variable_get(:@dir).should   == :down
    end

    it "creates the coordinates for every letter in the word going down" do
      placement = Crossword::Placement.new("hello", 1, 1, :down)
      placement.instance_variable_get(:@coords).should == {
        [1,1] => 'h',
        [2,1] => 'e',
        [3,1] => 'l',
        [4,1] => 'l',
        [5,1] => 'o'
      }
    end

    it "creates the coordinates for every letter in the word going across" do
      placement = Crossword::Placement.new("hello", 1, 1, :across)
      placement.instance_variable_get(:@coords).should == {
        [1,1] => 'h',
        [1,2] => 'e',
        [1,3] => 'l',
        [1,4] => 'l',
        [1,5] => 'o'
      }
    end
  end

  describe "#intersection" do
    let(:placement) { Crossword::Placement.new("hello", 2, 4, :down) }

    it "returns the coordinate where the placements intersect" do
      other = Crossword::Placement.new("world", 5, 1, :across)
      placement.intersection(other).should == [5, 4]
    end

    it "returns false if the placements do not intersect" do
      other = Crossword::Placement.new("world", 2, 6, :down)
      placement.intersection(other).should == false
    end

    it "returns nil if the placments intersect but don't share a letter" do
      other = Crossword::Placement.new("work", 5, 1, :across)
      placement.intersection(other).should be_nil
    end
  end
end
