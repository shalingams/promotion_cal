#!/usr/bin/env ruby

# Require Ruby 1.8+
# To run 'ruby code.rb'

require 'pp'

class PromotionEngine
  attr_accessor :promotions

  def initialize(promotions)
    @promotions = promotions
  end

  def apply_promotions(invoice)
    # Get all applicable promos for this invoce
    discount_promos = invoice[:lines].map do |line|
      # Find product based promotions
      promotions_to_item = promotions.map{|promo| promo if promo[:item] == line[:item] && promo[:applicable_type] == "product" && line[:qty] >= promo[:min_qty] }
      # Find category based promotions
      promotions_to_category = promotions.map{|promo| promo if promo[:item] == line[:category] && promo[:applicable_type] == "category" && line[:qty] >= promo[:min_qty]}
      # Concat and compact all promotions
      applicable_promos = (promotions_to_item + promotions_to_category).compact
      cal_discount(line, applicable_promos)
    end

    # Fnd the promotion which is advantage for the customer
    applicable_promotion = discount_promos.sort! {|a, b| a[:discount] <=> b[:discount]}.first

    # compose promotion item
    line_promotion = {
      item: applicable_promotion[:title],#
      category: 'Promotion',
      qty: applicable_promotion[:promo_qty] && applicable_promotion[:promo_qty] > 0 ? applicable_promotion[:promo_qty] : 0,
      price: applicable_promotion[:discount]
    }

    # Add promotion item to lines in invoce
    invoice[:lines].push(line_promotion)
    invoice
  end

  def cal_discount(item, promos)
    promos_with_discount = promos.map do |promo|
      if promo[:item] == item[:item] && promo[:applicable_type] == "product" && promo[:promotion_type] == 'free-items'
        promo[:free_qty] = (item[:qty] / promo[:min_qty]).to_i
        promo[:discount] = promo[:free_qty] * item[:price] * -1
      elsif promo[:item] == item[:item] && promo[:applicable_type] == "product" && promo[:promotion_type] == 'fixed-amount'
        promo[:discount] = promo[:promo_amount] * -1
      elsif promo[:item] == item[:category] && promo[:applicable_type] == "category" && promo[:promotion_type] == 'fixed-amount'
        promo[:discount] = promo[:promo_amount] * -1
      end
      promo
    end
    promos_with_discount.sort! {|a, b| a[:discount] <=> b[:discount]}.first
  end
end


invoice_a = {
  id: 1,
  lines: [
    {
      item: 'Banana',
      category: 'Fruits',
      qty: 3,
      price: 2.5
    }
  ]
}

invoice_b = {
  id: 1,
  lines: [
    {
      item: 'Mango',
      category: 'Fruits',
      qty: 6,
      price: 4.5
    },
    {
      item: 'Banana',
      category: 'Fruits',
      qty: 3,
      price: 2.5
    }
  ]
}

promotions = [
    {
      title: 'Buy 1 Get 1 Free',
      promotion_type: 'free-items',
      applicable_type: 'product',
      min_qty: 2,
      item: 'Banana',
      promo_qty: 1,
      promo_amount: nil
    },
    {
      title: '4 Euros off',
      promotion_type: 'fixed-amount',
      applicable_type: 'product',
      min_qty: 2,
      item: 'Banana',
      promo_qty: nil,
      promo_amount: 4
    },
    {
      title: '3 Euros off',
      promotion_type: 'fixed-amount',
      applicable_type: 'product',
      min_qty: 2,
      item: 'Banana',
      promo_qty: nil,
      promo_amount: 3
    },
    {
      title: '5 Euros off for Fruits',
      promotion_type: 'fixed-amount',
      applicable_type: 'category',
      min_qty: 2,
      item: 'Fruits',
      promo_qty: nil,
      promo_amount: 5
    },
    {
      title: '6 Euros off',
      promotion_type: 'fixed-amount',
      applicable_type: 'product',
      min_qty: 4,
      item: 'Mango',
      promo_qty: nil,
      promo_amount: 6
    }
  ]

promo_eng = PromotionEngine.new(promotions)

pp "Updated invoice A"
pp promo_eng.apply_promotions(invoice_a)

pp "Updated invoice B"
pp promo_eng.apply_promotions(invoice_b)
