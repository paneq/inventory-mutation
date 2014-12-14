require "active_support/all"

class Inventory
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
    raise StandardError, "quantity too low" if qty - @reserved_quantity[identifier].sum - @sold_quantity[identifier].sum < 0
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

RSpec.describe Inventory do
  specify "can add product with initial available quantity" do
    inventory.register_product("WROCLOVE2014", 10)
  end

  specify "can get initial state" do
    inventory.register_product("WROCLOVE2014", 10)
    qty = inventory.available_quantity("WROCLOVE2014")
    expect(qty).to eq(10)

    qty = inventory.reserved_quantity("WROCLOVE2014")
    expect(qty).to eq(0)

    qty = inventory.sold_quantity("WROCLOVE2014")
    expect(qty).to eq(0)
  end

  specify "can reserve some quantity" do
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 5)

    qty = inventory.available_quantity("WROCLOVE2014")
    expect(qty).to eq(5)

    qty = inventory.reserved_quantity("WROCLOVE2014")
    expect(qty).to eq(5)
  end

  specify "can sell some reserved qty" do
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 5)
    inventory.sell_product("WROCLOVE2014", 5)

    qty = inventory.reserved_quantity("WROCLOVE2014")
    expect(qty).to eq(0)

    qty = inventory.sold_quantity("WROCLOVE2014")
    expect(qty).to eq(5)
  end

  specify "can change inventory qty" do
    inventory.register_product("WROCLOVE2014", 9)
    inventory.reserve_product("WROCLOVE2014", 5)
    inventory.sell_product("WROCLOVE2014", 4)
    inventory.change_quantity("WROCLOVE2014", 8)

    qty = inventory.reserved_quantity("WROCLOVE2014")
    expect(qty).to eq(1)

    qty = inventory.sold_quantity("WROCLOVE2014")
    expect(qty).to eq(4)

    qty = inventory.available_quantity("WROCLOVE2014")
    expect(qty).to eq(3)
  end

  specify "can't change inventory qty to lower value than sold and reserved" do
    inventory.register_product("WROCLOVE2014", 9)
    inventory.reserve_product("WROCLOVE2014", 5)
    inventory.sell_product("WROCLOVE2014", 4)
    inventory.change_quantity("WROCLOVE2014", 5)
    expect do
      inventory.change_quantity("WROCLOVE2014", 4)
    end.to raise_error(StandardError)
  end

  specify "can't reserve if not enough product" do
    inventory.register_product("WROCLOVE2014", 9)

    expect do
      inventory.reserve_product("WROCLOVE2014", 10)
    end.to raise_error(StandardError)

    inventory.reserve_product("WROCLOVE2014", 5)
    expect do
      inventory.reserve_product("WROCLOVE2014", 5)
    end.to raise_error(StandardError)
  end

  specify "can't sell if not enough product" do
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 4)
    expect do
      inventory.sell_product("WROCLOVE2014", 5)
    end.to raise_error(StandardError)

    inventory.sell_product("WROCLOVE2014", 2)
    expect do
      inventory.sell_product("WROCLOVE2014", 3)
    end.to raise_error(StandardError)
  end

  specify "can expire reserved product" do
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 4)
    inventory.expire_product("WROCLOVE2014", 4)
    inventory.reserve_product("WROCLOVE2014", 10)
  end

  specify "can't expire more qty than reserved" do
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 3)
    expect do
      inventory.expire_product("WROCLOVE2014", 4)
    end.to raise_error(StandardError)

    inventory.expire_product("WROCLOVE2014", 1)
    expect do
      inventory.expire_product("WROCLOVE2014", 3)
    end.to raise_error(StandardError)
  end

  specify "can refund sold product" do
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 7)
    inventory.sell_product("WROCLOVE2014", 6)
    inventory.refund_product("WROCLOVE2014", 5)

    qty = inventory.available_quantity("WROCLOVE2014")
    expect(qty).to eq(8)

    qty = inventory.reserved_quantity("WROCLOVE2014")
    expect(qty).to eq(1)

    qty = inventory.sold_quantity("WROCLOVE2014")
    expect(qty).to eq(1)
  end

  specify "can't refund more qty than sold" do
    inventory.register_product("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 7)
    inventory.sell_product("WROCLOVE2014", 6)

    expect do
      inventory.refund_product("WROCLOVE2014", 7)
    end.to raise_error(StandardError)

    inventory.refund_product("WROCLOVE2014", 5)
    expect do
      inventory.refund_product("WROCLOVE2014", 2)
    end.to raise_error(StandardError)
  end

  specify "multi product setup" do
    inventory.register_product("WROCLOVE2014", 9)
    inventory.change_quantity("WROCLOVE2014", 10)
    inventory.reserve_product("WROCLOVE2014", 8)
    inventory.sell_product("WROCLOVE2014", 6)
    inventory.refund_product("WROCLOVE2014", 4)
    inventory.expire_product("WROCLOVE2014", 1)

    inventory.register_product("DRUGCAMP2015", 90)
    inventory.change_quantity("DRUGCAMP2015", 100)
    inventory.reserve_product("DRUGCAMP2015", 80)
    inventory.sell_product("DRUGCAMP2015", 60)
    inventory.refund_product("DRUGCAMP2015", 40)
    inventory.expire_product("DRUGCAMP2015", 10)

    qty = inventory.reserved_quantity("WROCLOVE2014")
    expect(qty).to eq(1)
    qty = inventory.sold_quantity("WROCLOVE2014")
    expect(qty).to eq(2)
    qty = inventory.available_quantity("WROCLOVE2014")
    expect(qty).to eq(7)

    qty = inventory.reserved_quantity("DRUGCAMP2015")
    expect(qty).to eq(10)
    qty = inventory.sold_quantity("DRUGCAMP2015")
    expect(qty).to eq(20)
    qty = inventory.available_quantity("DRUGCAMP2015")
    expect(qty).to eq(70)
  end

  private

  def inventory
    @inventory ||= Inventory.new
  end
end
