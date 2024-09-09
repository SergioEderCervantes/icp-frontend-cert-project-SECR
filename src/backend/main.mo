import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Text "mo:base/Text";


import Types "./types";
import Data "./data";

actor {
  // State
  let cart = HashMap.HashMap<Text, Types.CartItem>(5, Text.equal, Text.hash);

  public shared query func getProducts(): async [Types.Product] {
    return Data.products;
  };

  type GetProductResultOk = [Types.CartItem];

  type GetProductResultErr = {
    #unauthorized;
  };

  type GetProductResult = Result.Result<GetProductResultOk, GetProductResultErr>;

  public shared query ({caller}) func getCart(): async GetProductResult {
    if (Principal.isAnonymous(caller)) return #err(#unauthorized);

    let cartIter = cart.vals();
    let cartArray = Iter.toArray<Types.CartItem>(cartIter);

    return #ok(cartArray);
  };

  type AddToCartResultOk = ();

  type AddToCartResultErr = {
    #unauthorized;
    #productNotFound;
  };

  type AddToCartResult = Result.Result<AddToCartResultOk, AddToCartResultErr>;

  public shared ({caller}) func addToCart(productId : Nat, quantity: Nat): async AddToCartResult {
    if (Principal.isAnonymous(caller)) return #err(#unauthorized);

    let maybeProduct = Array.find<Types.Product>(Data.products, func (product) { return product.id == productId});
    let itemId = Nat.toText(productId);
    let maybeProductInCart = cart.get(itemId);
    
    switch ((maybeProduct, maybeProductInCart)) {
      case (?product, null) {
        let cartItem = { product = product; quantity = quantity };

        cart.put(itemId, cartItem);

        return #ok();
      };
      case (?product, ?cartItem) {
        let newItem = { cartItem with quantity = cartItem.quantity + quantity };
        
        cart.put(itemId, newItem);

        return #ok();
      };
      case (_) return #err(#productNotFound);
    };
  };

  type RemoveFromCartResultOk = ();

  type RemoveFromCartResultErr = {
    #unauthorized;
    #productNotFound;
  };

  type RemoveFromCartResult = Result.Result<RemoveFromCartResultOk, RemoveFromCartResultErr>;

  public shared ({caller}) func removeFromCart(productId : Nat): async RemoveFromCartResult {
    if (Principal.isAnonymous(caller)) return #err(#unauthorized);

    let itemId = Nat.toText(productId);

    let maybeProductInCart = cart.get(itemId);

    switch (maybeProductInCart) {
      case (?_item) {
        cart.delete(itemId);

        return #ok();
      };
      case (null) return #err(#productNotFound);
    };

    return #ok();
  };

  // Nuevo método para cambiar la cantidad de un producto en el carrito
  type UpdateQuantityResultOk = ();

  type UpdateQuantityResultErr = {
    #unauthorized;
    #productNotFound;
  };

  type UpdateQuantityResult = Result.Result<UpdateQuantityResultOk, UpdateQuantityResultErr>;

  public shared ({caller}) func updateQuantity(productId: Nat, newQuantity: Nat): async UpdateQuantityResult {
    if (Principal.isAnonymous(caller)) return #err(#unauthorized);

    let itemId = Nat.toText(productId);

    let maybeProductInCart = cart.get(itemId);

    switch (maybeProductInCart) {
      case (?cartItem) {
        if (newQuantity == 0) {
          cart.delete(itemId);
        } else {
          let updatedItem = { cartItem with quantity = newQuantity };
          cart.put(itemId, updatedItem);
        };

        return #ok();
      };
      case (null) return #err(#productNotFound);
    };
  };
};
