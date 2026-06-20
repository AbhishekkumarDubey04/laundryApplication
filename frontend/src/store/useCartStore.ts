import { create } from 'zustand';

export interface CartItem {
  serviceId: number;
  serviceName: string;
  itemId: number;
  itemName: string;
  price: number;
  quantity: number;
  category: string;
}

export interface CouponInfo {
  code: string;
  discount_type: 'flat' | 'percentage';
  discount_value: number;
  discount_amount: number;
}

interface CartState {
  items: CartItem[];
  pickupAddressId: number | null;
  pickupDate: string | null;
  pickupTimeSlot: string | null;
  deliveryPreference: 'standard' | 'express' | 'same_day';
  coupon: CouponInfo | null;
  
  addItem: (item: Omit<CartItem, 'quantity'>) => void;
  removeItem: (serviceId: number, itemId: number) => void;
  updateQuantity: (serviceId: number, itemId: number, quantity: number) => void;
  setAddress: (addressId: number) => void;
  setSchedule: (date: string, slot: string) => void;
  setDeliveryPreference: (pref: 'standard' | 'express' | 'same_day') => void;
  setCoupon: (coupon: CouponInfo | null) => void;
  clearCart: () => void;
  
  getSubtotal: () => number;
  getDeliveryCharges: () => number;
  getTax: () => number;
  getGrandTotal: () => number;
}

const useCartStore = create<CartState>((set, get) => ({
  items: [],
  pickupAddressId: null,
  pickupDate: null,
  pickupTimeSlot: null,
  deliveryPreference: 'standard',
  coupon: null,

  addItem: (newItem) => {
    set((state) => {
      const existingIdx = state.items.findIndex(
        (i) => i.serviceId === newItem.serviceId && i.itemId === newItem.itemId
      );

      if (existingIdx > -1) {
        const updatedItems = [...state.items];
        updatedItems[existingIdx].quantity += 1;
        return { items: updatedItems };
      }

      return { items: [...state.items, { ...newItem, quantity: 1 }] };
    });
  },

  removeItem: (serviceId, itemId) => {
    set((state) => ({
      items: state.items.filter((i) => !(i.serviceId === serviceId && i.itemId === itemId))
    }));
  },

  updateQuantity: (serviceId, itemId, quantity) => {
    set((state) => {
      if (quantity <= 0) {
        return {
          items: state.items.filter((i) => !(i.serviceId === serviceId && i.itemId === itemId))
        };
      }
      return {
        items: state.items.map((i) =>
          i.serviceId === serviceId && i.itemId === itemId ? { ...i, quantity } : i
        )
      };
    });
  },

  setAddress: (pickupAddressId) => set({ pickupAddressId }),
  
  setSchedule: (pickupDate, pickupTimeSlot) => set({ pickupDate, pickupTimeSlot }),
  
  setDeliveryPreference: (deliveryPreference) => set({ deliveryPreference }),
  
  setCoupon: (coupon) => set({ coupon }),

  clearCart: () => set({
    items: [],
    pickupAddressId: null,
    pickupDate: null,
    pickupTimeSlot: null,
    deliveryPreference: 'standard',
    coupon: null
  }),

  getSubtotal: () => {
    return get().items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  },

  getDeliveryCharges: () => {
    const subtotal = get().getSubtotal();
    const coupon = get().coupon;
    const discount = coupon ? coupon.discount_amount : 0;
    
    // Free delivery above 500
    let charges = (subtotal - discount) >= 500 ? 0 : 30;
    
    if (get().deliveryPreference === 'express') {
      charges += 50;
    } else if (get().deliveryPreference === 'same_day') {
      charges += 100;
    }
    
    return charges;
  },

  getTax: () => {
    const subtotal = get().getSubtotal();
    const coupon = get().coupon;
    const discount = coupon ? coupon.discount_amount : 0;
    const taxable = Math.max(0, subtotal - discount);
    
    // 18% standard India service tax
    return parseFloat((taxable * 0.18).toFixed(2));
  },

  getGrandTotal: () => {
    const subtotal = get().getSubtotal();
    const coupon = get().coupon;
    const discount = coupon ? coupon.discount_amount : 0;
    const delivery = get().getDeliveryCharges();
    const tax = get().getTax();
    
    return parseFloat((subtotal - discount + delivery + tax).toFixed(2));
  }
}));

export default useCartStore;
