module Types {
  public type Product = {
    id: Nat;
    name: Text;
    description: Text;
    image: Text;
    price: Float;
  };

  public type CartItem = {
    product: Product;
    quantity: Nat;
  };
}
