require "active_support/all"

class Inventory
  Error = Class.new(StandardError)

  def initialize
    @available_quantity = Hash.new{|hash, key| hash[key] = [0] }
    @reserved_quantity  = Hash.new{|hash, key| hash[key] = [0] }
    @sold_quantity      = Hash.new{|hash, key| hash[key] = [0] }
  end

  def register_product(identifier, available_quantity)
    @available_quantity[identifier] << available_quantity
  end

  def available_quantity(identifier)
    @available_quantity[identifier].sum - @reserved_quantity[identifier].sum - @sold_quantity[identifier].sum
  end

  def change_quantity(identifier, qty)
    raise Error, "quantity too low" if qty - @reserved_quantity[identifier].sum - @sold_quantity[identifier].sum < 0
    @available_quantity[identifier] << -@available_quantity[identifier].last
    @available_quantity[identifier] << qty
  end

  def reserved_quantity(identifier)
    @reserved_quantity[identifier].sum
  end

  def sold_quantity(identifier)
    @sold_quantity[identifier].sum
  end

  def reserve_product(identifier, qty)
    raise StandardError, "quantity too big" if available_quantity(identifier) - qty < 0
    @reserved_quantity[identifier]  << qty
  end

  def sell_product(identifier, qty)
    raise StandardError, "quantity too big" if reserved_quantity(identifier) - qty < 0
    @reserved_quantity[identifier] << -qty
    @sold_quantity[identifier]     << qty
  end

  def expire_product(identifier, qty)
    raise StandardError, "quantity too big" if qty > reserved_quantity(identifier)
    @reserved_quantity[identifier] << -qty
  end

  def refund_product(identifier, qty)
    raise StandardError, "quantity too big" if qty > sold_quantity(identifier)
    @sold_quantity[identifier] << -qty
  end
end

