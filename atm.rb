require 'yaml'
require 'io/console'

class Atm
  attr_accessor :banknotes

  def initialize(config)
    self.banknotes = config['banknotes']
  end

  def withdraw_money(sum)
    banknotes.each do |key, value|
      count = sum / key
      #we have enough banknotes for sum or not?
      count = count > value ? value : count
      sum -= count * key
      value -= count
      banknotes[key] = value
    end
    self.banknotes
  end

  def get_balance
    balance = 0
    banknotes.each { |key, value| balance += key * value }
    balance
  end

  def withdraw_allowed?(sum)
    if sum > get_balance || sum < 0
      puts "ERROR: THE MAXIMUM AMOUNT AVAILABLE IN THIS ATM IS ₴#{self.get_balance}. PLEASE ENTER A DIFFERENT AMOUNT:"
      return false
    end
    banknotes.each do |key, value|
      count = sum / key
      #we have enough banknotes for sum or not?
      count = count > value ? value : count
      sum -= count * key
    end
    unless sum == 0
      puts 'ERROR: THE AMOUNT YOU REQUESTED CANNOT BE COMPOSED FROM BILLS AVAILABLE IN THIS ATM. PLEASE ENTER A DIFFERENT AMOUNT:'
      return false
    end
    true
  end
end

class AccountsBase
  attr_accessor :accounts, :current_account

  def initialize(config)
    self.accounts = config['accounts']
  end

  #get user data from accounts hash and init current_account
  def get_access(id, password)
    unless accounts[id]
      return nil
    end
    unless accounts[id]['password'] == password
      return nil
    end
    self.current_account = accounts[id]
  end

  def get_balance
    current_account['balance']
  end

  def change_balance(sum)
    current_account['balance'] -= sum
  end

  def balance_changing_allowed?(sum)
    if sum > get_balance || sum < 0
      puts 'ERROR: INSUFFICIENT FUNDS!! PLEASE ENTER A DIFFERENT AMOUNT:'
      return false
    end
    true
  end
end

class Session
  attr_accessor :account, :atm

  def initialize(account, atm)
    self.account = account
    self.atm = atm
  end

  def start_session
    option = 0
    puts "Hello, #{account.current_account['name']}!"
    until option == 3
      puts 'Please Choose From the Following Options:'
      puts '1. Display Balance'
      puts '2. Withdraw'
      puts '3. Log Out'
      option = STDIN.gets.to_i
      case option
      when 1
        puts "Your Current Balance is ₴#{account.get_balance}"
      when 2
        puts 'Enter Amount You Wish to Withdraw:'
        sum = STDIN.gets.to_i
        if account.balance_changing_allowed?(sum) && atm.withdraw_allowed?(sum)
          account.change_balance(sum)
          atm.withdraw_money(sum)
          puts "Your New Balance is ₴#{account.get_balance}"
        end
      when 3
        puts "#{account.current_account['name']}, Thank You For Using Our ATM. Good-Bye!"
        return
      else puts 'ERROR: NOT ALLOWED OPTION!'
      end
    end
  end

  def store_data(path_to_file)
    #Saving data to a YAML file for later use
    File.open(path_to_file, 'w') do |file|
      file.puts({'banknotes' => atm.banknotes, 'accounts' => account.accounts}.to_yaml)
    end
  end
end

config = YAML.load_file(ARGV.first || 'config.yml')

atm = Atm.new(config)

base = AccountsBase.new(config)

id = 0
password = ''

until base.get_access(id, password)
  puts 'Please Enter Your Account Number:'
  id = STDIN.gets.to_i
  puts 'Enter Your Password:'
  #Hide password input, but dosen't work in RubyMine debug console
  #password = STDIN.noecho(&:gets).chomp
  password = STDIN.gets.to_s.chop
  puts 'ERROR: ACCOUNT NUMBER AND PASSWORD DON\'T MATCH' unless base.get_access(id, password)
end
session = Session.new(base, atm)
session.start_session
session.store_data("result.yml")


