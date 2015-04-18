require "pry"
class Card
  attr_accessor :suit, :face_value
  def initialize(suit, face_value)
    @suit = suit
    @face_value = face_value
  end  

  def to_s
    "The #{face_value} of #{detail_suit}"
  end

  def detail_suit
    case suit
    when 'H' then 'Hearts'
    when 'D' then 'Diamonds'
    when 'S' then 'Spades'
    when 'C' then 'Clubs'
    end
  end
end

class Deck
  attr_accessor :cards, :count
  def initialize(count = 1)
    @cards = []
    @count = count
    get_decks(count)
    end
    scramble!
  end

  def get_decks(count)
    count.times do
      ['H', 'S', 'C', 'D'].each do |suit|
        ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'].each do |face_value|
          @cards << Card.new(suit, face_value)
        end
      end
    end
  end

  def scramble!
    cards.shuffle!
  end

  def deal_one
    get_decks(count) if card.nil?
    card = cards.pop
  end

  def size
    cards.size
  end
end

module Hand
  def show_hand
    puts "--- #{name}'s card ---"
    format_card = cards.map{|card| [card.detail_suit, card.face_value]}
    puts "=> #{format_card}"
    puts "=> Total: #{calculate_total}"
  end

  def calculate_total
    face_values = cards.map{|card| card.face_value}
    total = 0
    face_values.each do |value|
      if value == 'A'
        total += 11
      else
        total += (value.to_i == 0 ? 10 : value.to_i)
      end
    end
    ace_array = face_values.select{|value| value == 'A'}
    ace_array.size.times do
      break if total <= Blackjack::BLACKJACK_AMOUNT
      total -= 10
    end
    self.total = total
  end

  def add_card(new_card)
    self.cards << new_card
  end

  def is_busted?
    self.total > Blackjack::BLACKJACK_AMOUNT
  end
end

class Player
  include Hand
  attr_accessor :name, :cards, :bet, :asset, :total, :is_blackjack, :choose_hit, :choose_double, :result, :asset_change
  def initialize(name, asset = 500)
    @name = name
    @cards = []
    @bet = 0
    @asset = asset
    @is_blackjack = false
    @choose_hit = false
    @choose_double = false
    @result = "" # "win" or "lose" or "tie"
    @asset_change = ""
  end

  def place_bet(money)
    self.asset -= money
    self.bet += money
  end
end

module Message
  def prompt(msg)
    print "~ #{msg}"
  end

  def announce(msg)
    puts "=> #{msg}"
  end
end

class Dealer
  include Hand
  include Message
  attr_accessor :name, :cards, :asset, :total, :is_blackjack
  def initialize
    @name = "Dealer"
    @cards = []
    @asset = 100000000
    @total = 0
    @is_blackjack = false
  end

  def show_flop
    puts "--- Dealer's Hand ---"
    announce "First card is hidden"
    announce "Second card is #{cards[1]}"
  end
end


class Blackjack
  include Message
  attr_accessor :decks, :players, :dealer
  BLACKJACK_AMOUNT = 21
  DEALER_HIT_MIN = 17
  def initialize
    @decks = Deck.new
    @players = []
    @dealer = Dealer.new
    players_join
  end

  def players_join
    system "clear"
    begin
      prompt "How many players are there?(1-7): "
      players_count = gets.chomp.to_i
    end until (1..7).include?players_count
    for i in (1..players_count) do
      prompt "#{i}th player's name: " 
      player = Player.new(gets.chomp)
      self.players << player
    end
  end

  def players_place_bet
    players.each do |player|
      loop do
        prompt "#{player.name}'s asset: #{player.asset}$. Please place bet: "
        input_bet = gets.chomp.to_f
        if input_bet > 0 && player.asset >= input_bet
          player.place_bet(input_bet)
          break
        else
          puts "Please input correct bet!"
          next
        end
      end
    end
  end

  def deal_cards
    # dealing a face up and a face down card
    2.times do
      dealer.add_card(decks.deal_one)
      players.each do |player|
        player.add_card(decks.deal_one)
      end
    end
  end

  def blackjack_or_bust?(player_or_dealer)
    if player_or_dealer.total == Blackjack::BLACKJACK_AMOUNT
      if player_or_dealer.is_a?(Dealer)
        player_or_dealer.is_blackjack = true
        announce "Dealer hit blackjack!"
      elsif player_or_dealer.is_a?(Player)
        player_or_dealer.is_blackjack = true
        announce "#{player_or_dealer.name} hit blackjack!"
      end
      true
    elsif player_or_dealer.is_busted?
      if player_or_dealer.is_a?(Dealer)
        announce "Dealer busted!"
      elsif player_or_dealer.is_a?(Player)
        announce "#{player_or_dealer.name} busted!"
        player_or_dealer.result = "lose"
      end
      true
    else
      false
    end
  end

  def player_turn
    str_arr1 = ["Choose to 1)Hit 2)Stay 3)Double : ", "Choose to 1)Hit 2)Stay : "]
    str_arr2 = ["1 or 2 or 3", "1 or 2"]
    choose_string = {true => 1, false => 0}
    players.each do |player|
      puts ""
      sleep(0.3)
      announce "Turning to #{player.name}..."
      player.show_hand
      next if blackjack_or_bust?(player)
      while !player.is_busted?
        prompt "#{str_arr1[choose_string[player.choose_hit]]}"
        response = gets.chomp.to_i
        if ![1, 2, 3].include?response
          puts "You must enter #{str_arr2[choose_string[player.choose_hit]]}"
          next
        end

        case response
        when 1
          player.choose_hit = true
          new_card = decks.deal_one
          announce "Dealing card to #{player.name}: [#{new_card.detail_suit}, #{new_card.face_value}]"
          player.add_card(new_card)
          player.calculate_total
          announce "#{player.name}'s total is now: #{player.total}"
          break if blackjack_or_bust?(player)
        when 2
          announce "#{player.name} chose to stay..."
          sleep(0.5)
          break
        when 3
          player.choose_double = true
          if player.asset >= player.bet
            player.place_bet(player.bet)
            new_card = decks.deal_one
            puts "Dealing card to #{player.name}: [#{new_card.detail_suit}, #{new_card.face_value}]"
            player.add_card(decks.deal_one)
            player.calculate_total
            announce "#{player.name}'s total is now: #{player.total}"
            break if blackjack_or_bust?(player)
          else
            announce "Sorry, you have not enough money!"
            next
          end
          break
        end
      end
    end
  end

  def dealer_turn
    puts ""
    announce "Dealer's turn..."
    sleep(0.3)
    blackjack_or_bust?(dealer)
    while dealer.calculate_total < Blackjack::DEALER_HIT_MIN
      new_card = decks.deal_one
      announce "Dealing card to dealer: [#{new_card.detail_suit}, #{new_card.face_value}]"
      dealer.add_card(decks.deal_one)
      announce "Dealer' total is now: #{dealer.total}"
      break if blackjack_or_bust?(dealer)
    end
    announce "Dealer stay at #{dealer.total}"
  end

  def result_msg(player)
    msg = {
      "win" => "#{player.name}: #{player.name} won! (#{player.name}: #{player.total}, Dealer: #{dealer.total})",
      "lose" => "#{player.name}: #{player.name} lost! (#{player.name}: #{player.total}, Dealer: #{dealer.total})",
      "tie" => "#{player.name}: It's a tie! (#{player.name}: #{player.total}, Dealer: #{dealer.total})"}
    msg[player.result]
  end

  def who_won
    puts ""
    puts "***** ANNONCING RESULT *****"
    players.each do |player|
      if !dealer.is_busted? && !player.is_busted?
        if player.total > dealer.total
          player.result = "win"
          announce result_msg(player)
        elsif player.total < dealer.total
          player.result = "lose"
          announce result_msg(player)
        else
          player.result = "tie"
          announce result_msg(player)
        end
      elsif dealer.is_busted? && !player.is_busted?
        player.result = "win"
        announce "#{result_msg(player)} Dealer busted!"
      else
        player.result = "lose"
        announce "#{player.name} busted!"   
      end
    end
  end

  def calculate_bet
    players.each do |player|
      if player.is_blackjack
        if dealer.is_blackjack
          player.asset += player.bet
          player.asset_change = "0$"
        else
          dealer.asset -= player.bet * 1.5
          player.asset += player.bet * 2.5
          player.asset_change = "+#{player.bet * 1.5}$"
        end
      else
        if player.result == "win"
          dealer.asset -= player.bet
          player.asset += player.bet * 2
          player.asset_change = "+#{player.bet}$"
        elsif player.result == "lose"
          dealer.asset += player.bet
          player.asset_change = "-#{player.bet}$"
        elsif player.result == "tie"
          player.asset += player.bet
          player.asset_change = "0$"
        else
          puts "There is a error occured in method: calculate_bet"
        end
      end
    end
  end

  def display_bet_info
    puts ""
    puts "***** BET INFO *****"
    players.each do |player|
      announce "#{player.name}: #{player.asset_change}. Current asset: #{player.asset}$"
    end
  end

  def reset
    system "clear"
    self.decks = Deck.new(players.size)
    dealer.cards = []
    dealer.total = 0
    dealer.is_blackjack = false
    players.each do |player|
      player.cards =[]
      player.bet = 0
      player.total = 0
      player.is_blackjack = false
      player.choose_hit = false
      player.choose_double = false
      player.result = "" # "win" or "lose" or "tie"
      player.asset_change = ""
    end
  end

  def play_again?
    if !players.empty?
      puts ""
      prompt "Would you like to play again? 1) yes 2) no : "
      if gets.chomp == '1'
        puts "Starting new game..."
        reset
        start
      else
        puts "Goodbye!"
      end
    else
      puts "Goodbye!"
    end
  end

  def welcome
    current_players_name = players.map{|player| player.name}
    announce "Welcome! #{current_players_name}"
  end

  def clear_players
    self.players = players.select{|player| player.asset > 0}
  end

  def start
    welcome
    players_place_bet
    deal_cards
    dealer.show_flop
    player_turn
    dealer_turn
    who_won
    calculate_bet
    display_bet_info
    clear_players
    play_again?
  end
end

game = Blackjack.new
game.start

