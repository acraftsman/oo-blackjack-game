# Description: There are two to eight people in this game, a dealer and seven players at most. And there are one or more decks. At first, dealer respectively deal two cards to players. According to the order, player choose to hit or stay. If player choose to hit, and finally his/her total points great than 21, player bursted. If player choose to stay, current total points are saved to compare.

# If dealer's total points great than or equal to 17, he/she must choose to stay. Otherwise, if dealer's total points less than 17, he or she must choose to hit. If dealer's total points great than 21, dealer bursted. And all players that haven't bursted won.

# Finally, Dealer compare with every player's total points. 
require "pry"
module Calculatable
  def calculate_total_points(cards)
    total = 0 
    cards.each do |card|
      point = card[1].to_i
      if point == 0
        total += 10
      else
        total += point
      end
    end
    arr_contain_a = cards.select{ |card| card[1] == 'A'}
    unless arr_contain_a.empty?
      arr_contain_a.size.times do
        total += 1
        if total > 21
          total -= 10
        end
      end
    end
  total
  end 

  def calculate_bet(dealer, players)
    players.each do |player|
      if player.result_info[:blackjack]
        if dealer.is_blackjack
          player.asset += player.bet
          player.result_info[:assect_change] = "0$"
        else
          dealer.asset -= player.bet * 1.5
          player.asset += player.bet * 1.5
          player.result_info[:assect_change] = "+#{player.bet * 1.5}$"
        end
      else
        if player.result_info[:result] == "win"
          dealer.asset -= player.bet
          player.asset += player.bet
          player.result_info[:assect_change] = "+#{player.bet}$"
        elsif player.result_info[:result] == "lose"
          player.asset -= player.bet
          dealer.asset += player.bet
          player.result_info[:assect_change] = "-#{player.bet}$"
        elsif player.result_info[:result] == "tie"
          player.result_info[:assect_change] = "0$"
        else
          puts "There is a error occured in method: calculate_bet"
        end
      end
    end
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

class Deck
  private
  SUIT = ['H', 'S', 'C', 'D']
  CARDS = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  public
  attr_accessor :cards, :count
  
  def initialize(count = 1)
    self.count = count
    self.cards = []
    count.times{ self.cards += SUIT.product(CARDS) }
  end

  def shuffle_decks
    self.cards.shuffle!
  end
end

class Dealer
  include Calculatable
  attr_accessor :asset, :decks, :cards, :total, :is_bursted, :is_blackjack
  def initialize(decks, asset = 1000000)
    self.asset = asset
    self.decks = decks 
    self.cards = []
    self.total = 0
    self.is_bursted = false
    self.is_blackjack = false
  end

  def deal(player)
    unless player.nil?
      player.cards << decks.cards.pop 
    end
    player.total = calculate_total_points(player.cards)
  end

  def choose
    loop do
      self.total = calculate_total_points(cards)
      if total.between?(1, 16) # 1<=total<=16
        self.cards << decks.cards.pop
      elsif total.between?(17, 20)
        break
      elsif total == 21
        self.is_blackjack = true
        break
      elsif total > 21
        self.is_bursted = true
        break
      end
    end
  end
end

class Player
  include Calculatable
  include Message
  attr_accessor :name, :cards, :asset, :bet, :total, :result_info, :insurance
  def initialize(name, asset = 500)
    self.name = name
    self.cards = []
    self.asset = asset#
    self.bet = 0
    self.total = 0
    self.result_info = {burst: false, result: "", blackjack: false, assect_change: ""}
    self.insurance = 0
  end

  def choose
    begin
      prompt "#{name}'s total: #{total}. Choose to 1)Hit 2)Stay : "
      hit_or_stay = gets.chomp.to_i
    end until [1, 2].include?hit_or_stay
    hit_or_stay
  end

  def betting
    begin
      prompt "#{name}'s asset: #{asset}$. Total: #{total}.\n"
      prompt "Input bet: "
      self.bet = gets.chomp.to_i
    end until bet > 0 && asset >= bet
  end
end

class Game
  include Calculatable
  include Message
  attr_accessor :decks, :dealer, :players, :result_info
  
  def initialize
    system "clear"
    self.players = []
    begin
      prompt "How many players are there?(1-7): "
      players_count = gets.chomp.to_i
    end until (1..7).include?players_count
    for i in (1..players_count) do
      prompt "#{i}th player's name: "
      self.players << Player.new(gets.chomp)
    end
    self.decks = Deck.new(players_count)
    decks.shuffle_decks
    self.dealer = Dealer.new(decks)
  end

  def play
    puts "GAME START..."
    2.times { dealer.deal(dealer) }
    players.each do |player|
      announce "Turning to #{player.name}..."
      sleep(0.3)
      announce "Dealer's cards: [\"X\", \"X\"], #{dealer.cards[1]}"
      2.times { dealer.deal(player) }
      announce "#{player.name}'s cards: #{player.cards}"
      player.total = calculate_total_points(player.cards)
      player.betting
      loop do
        hit_or_stay = player.choose
        if hit_or_stay == 1
          dealer.deal(player)
          announce "#{player.name}'s cards: #{player.cards}"
          player.total = calculate_total_points(player.cards)
          sleep(0.3)
          if player.total > 21
            player.result_info[:burst] = true
            announce "#{player.name} bursted! (total: #{player.total})"
            break
          elsif player.total == 21
            player.result_info[:blackjack] = true
            announce "#{player.name} blackjack!"
            break
          else
            next
          end
        elsif hit_or_stay == 2
          player.result_info[:blackjack] = true if player.total == 21
          announce "Saving #{player.name}'s total..."
          sleep(0.5)
          break
        end
      end
      puts ""
    end
    
    dealer.choose
    compare_with_dealer
    calculate_bet(dealer,players)
    display_bet_info
  end


  def compare_with_dealer
    puts ""
    puts "***** ANNONCING RESULT *****"
    players.each do |player|
      if dealer.is_bursted == true && player.result_info[:burst] == false
        player.result_info[:result] = "win"
        announce  "#{result_msg(player)} Dealer bursted!"
      elsif dealer.is_bursted == true && player.result_info[:burst] == true
        player.result_info[:result] = "tie"
        announce "#{result_msg(player)} You two all bursted!"
      else
        if !player.result_info[:burst]
          if player.total > dealer.total
            player.result_info[:result] = "win"  
            announce result_msg(player)
          elsif player.total < dealer.total
            player.result_info[:result] = "lose"  
            announce result_msg(player)
          else
            player.result_info[:result] = "tie"
            announce result_msg(player)
          end
        else
          player.result_info[:result] = "lose"
          announce result_msg(player)
        end
      end
    end
  end

  def result_msg(player)
    msg = {
      "win" => "#{player.name}: #{player.name} won! (#{player.name}: #{player.total}, Dealer: #{dealer.total})",
      "lose" => "#{player.name}: #{player.name} lost! (#{player.name}: #{player.total}, Dealer: #{dealer.total})",
      "tie" => "#{player.name}: It's a tie! (#{player.name}: #{player.total}, Dealer: #{dealer.total})"}
    msg[player.result_info[:result]]
  end

  def display_bet_info
    puts ""
    puts "***** BET INFO *****"
    players.each do |player|
      announce "#{player.name}: #{player.result_info[:assect_change]}. Current asset: #{player.asset}$"
    end
  end

  def reset
    system "clear"
    self.decks = Deck.new(players.size)
    decks.shuffle_decks
    dealer.decks = decks
    dealer.cards = []
    dealer.total = 0
    dealer.is_bursted = false
    dealer.is_blackjack = false
    players.each do |player|
      player.cards = []
      player.bet = 0
      player.total = 0
      player.result_info = {burst: false, result: "", blackjack: false, assect_change: ""}
    end
  end
end

game = Game.new
loop do
  game.play
  print "continue?(y/n) : "
  yes_or_no = gets.chomp
  break unless yes_or_no == 'y'
  game.reset
end

