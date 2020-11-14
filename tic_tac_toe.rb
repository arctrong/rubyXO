# Detecting arrow keyboard keys is a difficult problem.
# So a simpler solution will be used.

# The current version looks like working correctly (no strict tests done yet).
# But it can be used only with 3x3 field. With 4x4 field it consume too much resources.

# TODO Apply alpha–beta pruning (https://en.wikipedia.org/wiki/Alpha%E2%80%93beta_pruning#Pseudocode)


require 'io/console'


@DEBUG = false

@debug_file = nil
if @DEBUG
    @debug_file = File.open("debug.txt", "w")
end



@SIZE = 3
@HUMAN_NO = 1
@COMPUTER_NO = 2

usage = "An argument must be 'x' (first move) or 'o'."

current_player_no = nil
@human_mark = nil
@computer_mark = nil

if ARGV.length != 1
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


def copy_matrix(matrix)
    result = []
    matrix.each do |row|
        new_row = []
        row.each {|cell| new_row << cell}
        result << new_row
    end
    result
end


# https://en.wikipedia.org/wiki/Minimax#Pseudocode
# Without alpha–beta pruning
# (https://en.wikipedia.org/wiki/Alpha%E2%80%93beta_pruning#Pseudocode)
def minimax(matrix, player_no, depth, is_maximizing, debug_level)
    
    debug_level += 1
    
    if @DEBUG
        @debug_file.puts("L_#{debug_level} #{depth} #{matrix} #{player_no} #{is_maximizing}")
    end
    
    result = check(matrix)
    
    if @DEBUG
        if result == 0; @debug_file.puts("L_#{debug_level} leaf result = 0"); end
    end
    
    return 0 if result == 0
    if result
        result = result == player_no ? 1 : -1
        result = [is_maximizing ? result : -result, nil]
        
        if @DEBUG
            @debug_file.puts("L_#{debug_level} leaf value = #{result}")
        end
        
        return result
    end
    
    return 0 if depth == 0
    depth = depth ? depth - 1 : depth
    
    all_possible_moves = get_all_possible_moves(matrix)

    
    # if @DEBUG
        # @debug_file.puts("L_#{debug_level} #{all_possible_moves}")
    # end

    
    if is_maximizing
        value = -100
        move = nil
        # x, y = nil
        all_possible_moves.each do |y, x|
            matrix[y][x] = player_no
            new_value = minimax(matrix, next_turn_no(player_no), depth, false, debug_level)[0]
            
            if @DEBUG
                @debug_file.puts("L_#{debug_level} value = #{new_value}")
            end
            
            if new_value > value
                value = new_value
                move = [y, x]
            end
            matrix[y][x] = 0
        end
        
        if @DEBUG
            @debug_file.puts("L_#{debug_level} #{[value, move]} #{is_maximizing}")
        end
        
        return [value, move]
    else
        value = 100
        move = nil
        # x, y = nil
        all_possible_moves.each do |y, x|
            matrix[y][x] = player_no
            new_value = minimax(matrix, next_turn_no(player_no), depth, true, debug_level)[0]
            
            if @DEBUG
                @debug_file.puts("L_#{debug_level} value = #{new_value}")
            end
            
            if new_value < value
                value = new_value
                move = [y, x]
            end
            matrix[y][x] = 0
        end
        
        if @DEBUG
            @debug_file.puts("L_#{debug_level} #{[value, move]} #{is_maximizing}")
        end
        
        return [value, move]
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
        matrix_copy = copy_matrix(matrix)
        y, x = minimax(matrix_copy, player_no, nil, true, 0)[1]
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

@debug_file.close unless @debug_file.nil?

