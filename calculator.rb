require 'erb'
require 'ostruct'

class Calculation
  INSURANCE_KINDS = { JOB: 'Работа', LIFE: 'Жизнь', FULL: 'Полное' }.freeze
  RATE = 15 / 1200.0

  def initialize(person, insurance_kind = nil, format = :text)
    @person = person
    @insurance_kind = insurance_kind
    @loan_amount = @person.goods_cost - @person.downpayment
    @term = @person.term
    @age = @person.age
    @employment = @person.employment
    @format = format.to_sym
  end

  def calculate
    case @insurance_kind
    when 'LIFE'
      @insurance_amount = insurance_by_life(@age)
      @loan_amount += @insurance_amount
    when 'JOB'
      @insurance_amount = insurance_by_job(@employment)
      @loan_amount += @insurance_amount
    when 'FULL'
      insurance_amount_by_job = insurance_by_job(@employment)
      @loan_amount += insurance_amount_by_job
      insurance_amount_by_life = insurance_by_life(@age)
      @loan_amount += insurance_amount_by_life
      @insurance_amount = insurance_amount_by_job + insurance_amount_by_life
    else
      0.0
    end

    @monthly_payment = RATE * (RATE + 1)**@term / ((RATE + 1)**@term - 1) * @loan_amount

    case @format
    when :text
      report_text
    when :html
      report_html
    end
  end

  def insurance_by_life(age)
    if age < 30
      @loan_amount * (1.1 / 100.0) * @term
    elsif age < 60
      @loan_amount * (1.4 / 100.0) * @term
    else
      @loan_amount * (1.8 / 100.0) * @term
    end
  end

  def insurance_by_job(employment)
    case employment
    when :own_business
      @loan_amount / (1 - @term / 100.0 ) - @loan_amount
    when :clerk
      @loan_amount * 0.014
    else
      0.00
    end
  end

  def report_text
    puts "Сумма займа: #{@loan_amount.round(2)}"
    puts "Первоначальный взнос #{@person.downpayment}"
    puts "Ежемесячный платеж: #{@monthly_payment.round(2)}"
    puts "Срок кредита: #{@term} месяцев"
    puts "Сумма выплат: #{(@monthly_payment * @term).round(2) }"
    puts "Страхование: #{INSURANCE_KINDS[@insurance_kind.to_sym]}, #{@insurance_amount&.round(2)}"
  end

  def report_html
    template = File.read('./report_template.erb')
    result = ERB.new(template).result(binding)
    File.open('report.html', 'w+') do |f|
      f.write result
    end
  end
end

person = OpenStruct.new(goods_cost: 30_000, downpayment: 3000, term: 12, age: 44, employment: :own_business)

Calculation.new(person, *ARGV).calculate

