require 'set'

module Crossword
  class Solver
    attr_reader :solutions
    attr_reader :extra_words

    def initialize(slots, words)
      @slots = slots
      @words = words
      raise "must have 1 more word than slots" if @words.length != @slots.length + 1
      @words.each { |w| raise "#{w} is more than 10 letters, dipshit" if w.length > 10 }
    end

    def solve!
      @solutions = []
      @extra_words = []

      # try each word as the 'extra' word
      for extra_word in @words
        words = @words - [extra_word]

        # Get every possible permutation of the words
        perms = words.permutation.to_a
        perms.each do |perm|
          placements = []
          perm.each_with_index do |word, i|
            row, col, dir = @slots[i]
            placements << Crossword::Placement.new(word, row, col, dir)
          end
          board = Crossword::Board.new(*placements)

          if board.valid?
            @solutions << board
            @extra_words << extra_word
          end
        end
      end
    end # solve!
  end

  class Board
    attr_reader :placements, :grid

    def initialize(*placements)
      @placements = placements
      @grid = Array.new(10) { Array.new(10) { '*' } }

      @placements.each do |placement|
        placement.coords.each do |(row, col), char|
          @grid[row - 1][col - 1] = char
        end
      end
    end

    def valid?
      valid = true
      for placement in @placements
        coords = []
        others = @placements - [placement]

        for other in others
          coords << placement.intersection(other)
        end
        coords.reject! { |c| !c }
        valid = false if coords.empty?
      end
      valid
    end

    def inspect
      @grid.map { |row| row.join(' ') }.join("\n")
    end
    alias :to_s :inspect
  end

  class Placement
    attr_reader :word, :row, :col, :dir, :coords

    def initialize(word, row, col, dir)
      @word = word
      @row  = row
      @col  = col
      @dir  = dir

      @coords = {}
      @word.chars.each_with_index do |char, i|
        coord = dir == :down ? [@row + i, @col] : [@row, @col + i]
        @coords[coord] = char
      end
    end

    def intersection(other)
      coord = (@coords.keys & other.coords.keys).first
      if coord
        me    = @coords[coord]
        them  = other.coords[coord]
        me == them ? coord : nil
      else
        false
      end
    end

    def inspect
      "'#{@word}' - [#{@row}, #{@col}] - #{@dir}"
    end
    alias :to_s :inspect
  end
end
