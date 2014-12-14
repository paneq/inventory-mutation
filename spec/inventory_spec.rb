require "inventory"

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
