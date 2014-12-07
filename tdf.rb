require 'rubygems'
require 'mechanize'
require 'pry'
require 'sinatra'

class TDF

  LOGON_EMAIL = ENV['TDF_USER']
  LOGON_PASSWORD = ENV['TDF_PASSWORD']
  LOGON_PAGE = "https://secure2.tdf.org/welcome/login.html"

  PRICE_SELECTOR = ".DetailViewTicketPrice"
  TITLE_SELECTOR = ".DetailViewshowTitle"
  DATES_SELECTOR = "[name='PID'].DefaultFormField option"
  DESCRIPTION_SELECTOR = "table"

  def initialize
    @agent = Mechanize.new
    @shows = {}
  end

  def offerings
    Array.new.tap do |array|
      login.links.each do |link|
        if link.uri && link.uri.path =~ /OfferDetails/
          array << link
        end
      end
    end
  end

  def fetch_prices
    options = Array.new.tap do |array|
      offerings.each do |link|
        show_page = link.click
        title = show_page.search(TITLE_SELECTOR)
        price = show_page.search(PRICE_SELECTOR).text.gsub("Ticket Price: $", "").to_f
        dates = show_page.search(DATES_SELECTOR).map(&:text)
        description = show_page.search(DESCRIPTION_SELECTOR).text.strip
        array << {show: title.text, price: price, dates: dates, description: description}
      end
    end
    options.sort_by { |tix| tix[:price] }
  end

  def login
    page = @agent.get(LOGON_PAGE)
    form = page.form('frmLogon')
    form.LOGON_EMAIL = LOGON_EMAIL
    form.LOGON_PASSWORD = LOGON_PASSWORD
    @agent.submit(form, form.buttons.first)
  end
end

get '/' do
  t = TDF.new
  data = t.fetch_prices
  erb :index, locals: {tickets: data}
end
