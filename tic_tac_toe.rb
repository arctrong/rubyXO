# Detecting arrow keyboard keys is a difficult problem.
# So a simpler solution is used.

# The current version looks like working correctly (no strict tests done).
# The Minimax depth is limited for boards greater than 3x3. Otherwise thinks a move unreasonably long.

# On board 3x3 Alpha-beta pruning gives about 4 times less operations (see profiling files).
# On board 4x4 Alpha-beta pruning gives about 20 times less operations (see profiling files).


require 'io/console'


@DEBUG = false

@debug_file = nil
if @DEBUG
    @debug_file = File.open("debug.txt", "w")
end

@SIZE = 3
@HUMAN_NO = 1
@COMPUTER_NO = 2
@MINIMAX_DEPTH = 0


usage = "Usage: <sign> [<size>]
where: <sign>    'x' (first move) or 'o'
       <size>    reasonable size of the board, e.g. 3 for board 3x3"

current_player_no = nil
@human_mark = nil
@computer_mark = nil

if not [1, 2].include?(ARGV.length)
  puts usage
  exit
end

@human_mark = ARGV[0].upcase.strip
if ['X', 'O'].include?(@human_mark)
    current_player_no = if @human_mark == 'X' then @PLAYER_ID else @COMPUTER_NO end
    @computer_mark = if @human_mark == 'X' then 'O' else 'X' end
else
  puts usage
  exit
end

if ARGV.length == 2
    size = ARGV[1].to_i
    if size >= 2 and size <= 25
        @SIZE = size
    else
      puts usage
      exit
    end
end

# Limiting Minimax depth
max_steps = 500_000_000
current_steps = 1
(1..@SIZE * @SIZE).reverse_each do |i|
    current_steps *= i
    break if current_steps > max_steps
    @MINIMAX_DEPTH += 1
end

@profiling_file = File.open("profiling.txt", "w")
@profiling_file.puts "@SIZE=#{@SIZE}, @MINIMAX_DEPTH=#{@MINIMAX_DEPTH}"
@step_count = 0

def next_turn_no(turn_no)
    return turn_no == @COMPUTER_NO ? @HUMAN_NO : @COMPUTER_NO
end


@STEPX = 4
@STEPY = 2
@MOVE_TOTAL = @SIZE * @SIZE

@keys = {'8' => [0, -1], 'i' => [0, -1], 'I' => [0, -1],
         '4' => [-1, 0], 'j' => [-1, 0], 'J' => [-1, 0],
         '5' => [0, 1], '2' => [0, 1], 'k' => [0, 1], 'K' => [0, 1],
         '6' => [1, 0], 'l' => [1, 0], 'L' => [1, 0],
         "\n" => :E, ' ' => :E, 
         'q' => :Q, 'Q' => :Q}

@M = []
@SIZE.times do
    col = []
    @SIZE.times {col << 0}
    @M << col
end 

@x = 0
@y = 0
@move_count = 0

# Returns a number > 0 if one of the players wins, `nil` if no one wins and the game isn't
# finished, 0 if the game is finished and it's a draw.
def check(matrix)

    def check_cell(cell, value)
        if cell == 0
           return nil
        elsif value.nil?
            value = cell
        elsif cell != value
           return nil
        end
        return value
    end

    # Checking down-right diagonal
    value = nil
    (0...@SIZE).each do |i|
        break if (value = check_cell(matrix[i][i], value)).nil?
    end
    return value if value
    
    # Checking up-right diagonal
    value = nil
    (0...@SIZE).each do |i|
        break if (value = check_cell(matrix[@SIZE - i - 1][i], value)).nil?
    end
    return value if value

    # Checking columns
    (0...@SIZE).each do |col|
        value = nil
        matrix.each do |row|
            break if (value = check_cell(row[col], value)).nil?
        end
        return value if value
    end
    
    # Checking rows
    matrix.each do |row|
        value = nil
        row.each do |cell|
            break if (value = check_cell(cell, value)).nil?
        end
        return value if value
    end
    
    # Checking whether the game is unfinished
    matrix.each do |row|
        row.each {|cell| return nil if cell == 0}
    end
    
    return 0
end


def print_result(result)

    print "\033[#{(@SIZE - @y) * @STEPY}B\033[#{(@SIZE - @x) * @STEPX}D\033[2D"
    puts

    if !result
        puts "The game is unfinished."
    elsif result == 0
        puts "Draw!"
    elsif result == @HUMAN_NO
        puts "The human (#{@human_mark}) wins!"
    else
        puts "The computer (#{@computer_mark}) wins!"
    end
end

puts 
puts "Minimax depth: #{@MINIMAX_DEPTH}"
puts 
puts 'Use the following key sets for navigation:'
puts 
puts '    8          i    i.e. 8, i    - up     4, j - left'
puts '  4 5 6  or  j k l       5, 2, k - down   6, l - right'
puts '    2                    '
puts 
puts '  Enter, Space - make a move'
puts '  q - exit'
puts 
puts "+#{'---+' * @SIZE}"
@SIZE.times do
    puts "|#{'   |' * @SIZE}"
    puts "+#{'---+' * @SIZE}"
end

print "\033[#{@SIZE * @STEPY}A\033[2C"


def move_cursor(x, y)
    dx = (x - @x) * @STEPX
    dy = (y - @y) * @STEPY
    @x = x
    @y = y
    if dx > 0
        print "\033[#{dx}C"
    elsif dx < 0
        print "\033[#{-dx}D"
    end
    if dy > 0
        print "\033[#{dy}B"
    elsif dy < 0
        print "\033[#{-dy}A"
    end
end


def print_mark(mark)
    print "#{mark}\033[D"
end


def read_move(matrix)
    
    loop do
        k = @keys.fetch(STDIN.getch, :NIL)
        
        if k == :Q
            return :Q
        end
        
        if k == :NIL
        elsif k == :E
            if matrix[@y][@x] == 0
                matrix[@y][@x] = @HUMAN_NO
                print_mark(@human_mark)
                return
            else
                print "\a"
            end
        else
            x = @x + k[0]
            y = @y + k[1]
            next if x >= @SIZE or y >= @SIZE or x < 0 or y < 0
            move_cursor(x, y)
        end
    end
end


def next_possible_move(matrix)
    (0...@SIZE).each do |row|
        (0...@SIZE).each {|col| return [row, col] if matrix[row][col] == 0}
    end
    return nil
end


def get_all_possible_moves(matrix)
    result = []
    (0...@SIZE).each do |row|
        (0...@SIZE).each {|col| matrix[row][col] == 0 ? result << [row, col] : nil}
    end
    return result
end


def all_possible_moves(matrix)
    (0...@SIZE).each do |row|
        (0...@SIZE).each do |col|
            yield [row, col] if matrix[row][col] == 0
        end
    end
end


def copy_matrix(matrix)
    result = []
    matrix.each do |row|
        new_row = []
        row.each {|cell| new_row << cell}
        result << new_row
    end
    result
end


# Minimax without alpha–beta pruning
# https://en.wikipedia.org/wiki/Minimax#Pseudocode
def minimax(matrix, player_no, depth, is_maximizing)

    @step_count += 1 # profiling
    
    result = check(matrix)
    
    return 0 if result == 0
    if result
        result = result == player_no ? 1 : -1
        return is_maximizing ? result : -result
    end
    
    return 0 if depth == 0
    depth = depth ? depth - 1 : depth
    
    next_player_no = next_turn_no(player_no)
    if is_maximizing
        value = -100
        all_possible_moves(matrix) do |y, x|
            matrix[y][x] = player_no
            new_value = minimax(matrix, next_player_no, depth, false)
            matrix[y][x] = 0
            value = [new_value, value].max
        end
        return value
    else
        value = 100
        all_possible_moves(matrix) do |y, x|
            matrix[y][x] = player_no
            new_value = minimax(matrix, next_player_no, depth, true)
            matrix[y][x] = 0
            value = [new_value, value].min
        end
        return value
    end
end


# Minimax with alpha–beta pruning
# https://en.wikipedia.org/wiki/Alpha%E2%80%93beta_pruning#Pseudocode
# https://en.wikipedia.org/wiki/Minimax#Pseudocode
def alphabeta(matrix, player_no, depth, alpha, beta, is_maximizing)
    
    @step_count += 1 # profiling
    
    result = check(matrix)
    
    return 0 if result == 0
    if result
        result = result == player_no ? 1 : -1
        return is_maximizing ? result : -result
    end
    
    return 0 if depth == 0
    depth = depth ? depth - 1 : depth
    
    next_player_no = next_turn_no(player_no)
    if is_maximizing
        value = -100
        all_possible_moves(matrix) do |y, x|
            matrix[y][x] = player_no
            new_value = alphabeta(matrix, next_player_no, depth, alpha, beta, false)
            matrix[y][x] = 0
            value = [new_value, value].max
            alpha = [alpha, value].max
            break if alpha >= beta
        end
        return value
    else
        value = 100
        all_possible_moves(matrix) do |y, x|
            matrix[y][x] = player_no
            new_value = alphabeta(matrix, next_player_no, depth, alpha, beta, true)
            matrix[y][x] = 0
            value = [new_value, value].min
            beta = [beta, value].min
            break if alpha >= beta
        end
        return value
    end
end


def apply_move(matrix, y, x, player_no, player_mark)
    matrix[y][x] = player_no
    save_x = @x
    save_y = @y
    move_cursor(x, y)
    print_mark(player_mark)
    move_cursor(save_x, save_y)
end


def make_move(matrix, player_no, player_mark)
    # Intelligent minimax algorithm
    if @move_count < 1
        x = rand 0...@SIZE
        y = rand 0...@SIZE
    else
        @step_count += 0 # profiling
    
        # First move is done randomly (of by the human player),
        # the second level we implement ourself.
        minimax_depth = @MINIMAX_DEPTH - 2
        matrix_copy = copy_matrix(matrix)
        best_move = nil
        best_score = -100
        next_player_no = next_turn_no(player_no)
        all_possible_moves(matrix_copy) do |y, x|
            matrix_copy[y][x] = player_no
            # score = alphabeta(matrix_copy, next_player_no, minimax_depth, -100, 100, false)
            score = minimax(matrix_copy, next_player_no, minimax_depth, false)
            matrix_copy[y][x] = 0
            if score > best_score
                best_score = score
                best_move = [y, x]
            end
        end
        y, x = best_move
        
        @profiling_file.puts @step_count
    end
    apply_move(matrix, y, x, player_no, player_mark)
end


def make_move_simple(matrix, player_no, player_mark)
    # First simplest implementation
    y, x = next_possible_move(matrix)
    apply_move(matrix, y, x, player_no, player_mark)
end


while @move_count < @MOVE_TOTAL do
    
    if current_player_no == @COMPUTER_NO
        make_move(@M, @COMPUTER_NO, @computer_mark)
        # make_move_simple(@M, @COMPUTER_NO, @computer_mark)
        current_player_no = @HUMAN_NO
    else
        if read_move(@M) == :Q
            print_result(nil)
            return
        end
        current_player_no = @COMPUTER_NO
    end
    
    if result = check(@M)
        print_result(result)
        return
    end
    
    @move_count += 1
end

print_result(0)

@profiling_file.close unless @profiling_file.nil?

