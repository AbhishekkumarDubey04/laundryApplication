import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Card, Button, Steps, Form, Input, Radio, Space, Badge, Alert, message, Select, Modal } from 'antd';
import {
  Shirt,
  MapPin,
  Calendar,
  Sparkles,
  ChevronRight,
  ChevronLeft,
  Trash2,
  CheckCircle,
  Clock,
  Info,
  DollarSign,
  Percent,
  IndianRupee,
  ShieldCheck,
  Plus
} from 'lucide-react';
import api from '../services/api.ts';
import useCartStore, { CartItem } from '../store/useCartStore.ts';

const { Step } = Steps;

// Dynamic loader for Razorpay script
const loadRazorpayScript = () => {
  return new Promise((resolve) => {
    const script = document.createElement('script');
    script.src = 'https://checkout.razorpay.com/v1/checkout.js';
    script.onload = () => resolve(true);
    script.onerror = () => resolve(false);
    document.body.appendChild(script);
  });
};

export default function BookingFlow({ inlined = false, onClose }: { inlined?: boolean; onClose?: () => void }) {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  
  const {
    items: cartItems,
    pickupAddressId,
    pickupDate,
    pickupTimeSlot,
    deliveryPreference,
    coupon,
    addItem,
    removeItem,
    updateQuantity,
    setAddress,
    setSchedule,
    setDeliveryPreference,
    setCoupon,
    clearCart,
    getSubtotal,
    getDeliveryCharges,
    getTax,
    getGrandTotal
  } = useCartStore();

  const [currentStep, setCurrentStep] = useState(0);
  const [couponCodeInput, setCouponCodeInput] = useState('');
  const [validatingCoupon, setValidatingCoupon] = useState(false);
  const [addressModalOpen, setAddressModalOpen] = useState(false);
  const [addressForm] = Form.useForm();

  // Queries
  const { data: services = [], isLoading: servicesLoading } = useQuery({
    queryKey: ['services'],
    queryFn: async () => {
      const res = await api.get('/services');
      return res.data;
    }
  });

  const { data: addresses = [], isLoading: addressesLoading } = useQuery({
    queryKey: ['addresses'],
    queryFn: async () => {
      const res = await api.get('/addresses');
      return res.data;
    }
  });

  const { data: itemCatalog = [] } = useQuery({
    queryKey: ['services/items'],
    queryFn: async () => {
      const res = await api.get('/services/items');
      return res.data;
    }
  });

  // Mutations
  const createAddressMutation = useMutation({
    mutationFn: async (values: any) => {
      const res = await api.post('/addresses', values);
      return res.data;
    },
    onSuccess: (newAddr) => {
      queryClient.invalidateQueries({ queryKey: ['addresses'] });
      setAddress(newAddr.id);
      message.success('Address added successfully');
      setAddressModalOpen(false);
      addressForm.resetFields();
    }
  });

  // Generate next 7 days for pickup schedule
  const getNextDays = () => {
    const days = [];
    const options: Intl.DateTimeFormatOptions = { weekday: 'short', day: 'numeric', month: 'short' };
    for (let i = 1; i <= 7; i++) {
      const d = new Date();
      d.setDate(d.getDate() + i);
      days.push({
        value: d.toISOString().split('T')[0],
        label: d.toLocaleDateString('en-IN', options)
      });
    }
    return days;
  };

  const timeSlots = ['9-11 AM', '11-1 PM', '1-3 PM', '3-5 PM', '5-7 PM'];

  // Validate coupon via api
  const handleApplyCoupon = async () => {
    if (!couponCodeInput.trim()) return;
    setValidatingCoupon(true);
    try {
      const res = await api.post('/coupons/validate', {
        code: couponCodeInput.toUpperCase(),
        amount: getSubtotal()
      });
      const data = res.data;
      setCoupon({
        code: data.code,
        discount_type: data.discount_type,
        discount_value: parseFloat(data.discount_value),
        discount_amount: parseFloat(data.discount_amount)
      });
      message.success(`Coupon ${data.code} applied! Saved ₹${data.discount_amount}`);
    } catch (err: any) {
      message.error(err.response?.data?.error || 'Invalid coupon code');
      setCoupon(null);
    } finally {
      setValidatingCoupon(false);
    }
  };

  // Step Nav validation controls
  const handleNext = () => {
    if (currentStep === 0 && cartItems.length === 0) {
      message.warning('Please add at least one clothing item to continue.');
      return;
    }
    if (currentStep === 1 && !pickupAddressId) {
      message.warning('Please select a pickup address.');
      return;
    }
    if (currentStep === 2 && (!pickupDate || !pickupTimeSlot)) {
      message.warning('Please select both pickup date and time slot.');
      return;
    }
    setCurrentStep(currentStep + 1);
  };

  const handlePrev = () => {
    setCurrentStep(currentStep - 1);
  };

  // Submit and Trigger checkout payment integrations
  const handleCheckoutSubmit = async (method: 'cod' | 'razorpay') => {
    try {
      // 1. Create order record on backend
      const orderRes = await api.post('/orders', {
        pickup_address_id: pickupAddressId,
        pickup_date: pickupDate,
        pickup_time_slot: pickupTimeSlot,
        delivery_preference: deliveryPreference,
        coupon_code: coupon ? coupon.code : null,
        items: cartItems.map((i) => ({
          item_id: i.itemId,
          service_id: i.serviceId,
          quantity: i.quantity
        }))
      });

      const { order } = orderRes.data;

      // 2. Process payments method
      const payRes = await api.post('/payments/create', {
        order_id: order.id,
        method
      });

      if (method === 'cod') {
        message.success('Laundry booked successfully! COD selected.');
        clearCart();
        navigate(`/track/${order.id}`);
        return;
      }

      // Online pay Razorpay flows
      const paymentConfig = payRes.data;

      if (paymentConfig.mock) {
        // Simulated mock Razorpay Modal
        Modal.info({
          title: 'Simulated Razorpay Sandbox Payment',
          content: (
            <div className="space-y-3 pt-3">
              <p>Amount to Pay: <strong>₹{order.grand_total}</strong></p>
              <p className="text-xs text-slate-500">Integrating client checkout scripts... simulating sandbox transaction validation.</p>
            </div>
          ),
          okText: 'Simulate Success Payment',
          onOk: async () => {
            try {
              // Verify mock payment signatures
              await api.post('/payments/verify', {
                order_id: order.id,
                razorpay_order_id: paymentConfig.id,
                razorpay_payment_id: `pay_mock_${Math.random().toString(36).substr(2, 9)}`
              });
              message.success('Simulated transaction approved!');
              clearCart();
              navigate(`/track/${order.id}`);
            } catch (error) {
              message.error('Mock payment signature validation failed.');
            }
          }
        });
        return;
      }

      // Live Razorpay logic
      const scriptLoaded = await loadRazorpayScript();
      if (!scriptLoaded) {
        message.error('Failed to load Razorpay payment window. Please try again.');
        return;
      }

      const options = {
        key: paymentConfig.key_id,
        amount: paymentConfig.amount,
        currency: paymentConfig.currency,
        name: 'LaundryIndia',
        description: `Payment for Order #${order.id}`,
        order_id: paymentConfig.id,
        handler: async function (response: any) {
          try {
            await api.post('/payments/verify', {
              order_id: order.id,
              razorpay_order_id: response.razorpay_order_id,
              razorpay_payment_id: response.razorpay_payment_id,
              razorpay_signature: response.razorpay_signature
            });
            message.success('Payment verification successful!');
            clearCart();
            navigate(`/track/${order.id}`);
          } catch (error) {
            message.error('Signature verification failed.');
          }
        },
        prefill: {
          contact: order.user_phone,
          name: order.user_name
        },
        theme: {
          color: '#1E88E5'
        }
      };

      const rzp = new (window as any).Razorpay(options);
      rzp.open();
    } catch (err: any) {
      console.error(err);
      message.error(err.response?.data?.error || 'Failed to place order.');
    }
  };

  const getActiveAddressObject = () => {
    return addresses.find((a: any) => a.id === pickupAddressId);
  };

  return (
    <div className={inlined ? "pb-24 pt-4" : "min-h-screen pb-16"} style={{ backgroundColor: 'var(--bg-primary)' }}>
      {/* Mini navbar */}
      {!inlined && (
        <div className="glass-panel sticky top-0 z-40 rounded-none border-b bg-white" style={{ borderBottom: '1px solid var(--border-color)' }}>
          <div className="max-w-6xl mx-auto px-4 py-4 flex items-center justify-between">
            <div className="flex items-center space-x-2 cursor-pointer" onClick={() => { if (onClose) { onClose(); } else { navigate('/dashboard'); } }}>
              <ChevronLeft size={20} className="text-slate-700" />
              <span className="font-bold text-base">Exit Booking</span>
            </div>
            <span className="font-semibold text-sm">Step {currentStep + 1} of 4</span>
          </div>
        </div>
      )}

      <div className={inlined ? "max-w-4xl mx-auto px-4 space-y-6" : "max-w-4xl mx-auto px-4 mt-8 space-y-6"}>
        <Steps current={currentStep} className="hidden sm:flex">
          <Step title="Add Items" icon={<Shirt size={18} />} />
          <Step title="Address" icon={<MapPin size={18} />} />
          <Step title="Schedule" icon={<Calendar size={18} />} />
          <Step title="Checkout" icon={<ShieldCheck size={18} />} />
        </Steps>

        {/* STEP 1: Add clothes rates items */}
        {currentStep === 0 && (
          <div className="space-y-6">
            <div className="text-center space-y-2">
              <h2 className="text-2xl font-bold" style={{ fontFamily: 'Outfit' }}>Add Clothing Items</h2>
              <p className="text-sm" style={{ color: 'var(--text-muted)' }}>Choose items and services to wash, iron, or dry clean.</p>
            </div>

            {servicesLoading ? (
              <div className="text-center py-12 text-slate-400">Loading catalog rates...</div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {services.map((service: any) => (
                  <Card key={service.id} className="glass-panel border-none shadow-md overflow-hidden flex flex-col justify-between" title={
                    <div className="flex items-center space-x-2">
                      <span className="font-bold text-sm">{service.name}</span>
                    </div>
                  }>
                    <div className="space-y-4 max-h-[350px] overflow-y-auto pr-1">
                      {service.items.map((item: any) => {
                        const cartMatch = cartItems.find((c) => c.serviceId === service.id && c.itemId === item.id);
                        const quantity = cartMatch ? cartMatch.quantity : 0;
                        return (
                          <div key={item.id} className="flex justify-between items-center py-2 border-b last:border-0 border-slate-100">
                            <div>
                              <span className="font-medium text-sm block">{item.name}</span>
                              <span className="text-xs text-green-600 font-semibold block">₹{item.price}</span>
                            </div>
                            
                            {quantity > 0 ? (
                              <Space size="small">
                                <Button size="small" onClick={() => updateQuantity(service.id, item.id, quantity - 1)}>-</Button>
                                <span className="font-bold text-xs px-2">{quantity}</span>
                                <Button size="small" onClick={() => updateQuantity(service.id, item.id, quantity + 1)}>+</Button>
                              </Space>
                            ) : (
                              <Button size="small" type="primary" ghost onClick={() => addItem({
                                serviceId: service.id,
                                serviceName: service.name,
                                itemId: item.id,
                                itemName: item.name,
                                price: item.price,
                                category: item.category
                              })}>
                                Add
                              </Button>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  </Card>
                ))}
              </div>
            )}

            {/* Shopping Cart Summary strip */}
            {cartItems.length > 0 && (
              <Card className="glass-panel border-none shadow-lg gradient-premium-card">
                <div className="flex justify-between items-center">
                  <div>
                    <span className="text-xs font-semibold block" style={{ color: 'var(--text-muted)' }}>SELECTED BASKET</span>
                    <span className="text-lg font-bold block">{cartItems.reduce((sum, i) => sum + i.quantity, 0)} Items Added</span>
                  </div>
                  <div className="flex items-center space-x-6">
                    <span className="text-lg font-bold text-slate-800">Subtotal: ₹{getSubtotal()}</span>
                    <Button type="primary" size="large" className="gradient-primary-bg border-none" onClick={handleNext}>
                      Proceed to Address <ChevronRight size={16} />
                    </Button>
                  </div>
                </div>
              </Card>
            )}
          </div>
        )}

        {/* STEP 2: Select/Add pickup address */}
        {currentStep === 1 && (
          <div className="space-y-6">
            <div className="text-center space-y-2">
              <h2 className="text-2xl font-bold" style={{ fontFamily: 'Outfit' }}>Select Pickup Address</h2>
              <p className="text-sm" style={{ color: 'var(--text-muted)' }}>Where should our representative collect your clothes?</p>
            </div>

            {addressesLoading ? (
              <div className="text-center py-12 text-slate-400">Loading saved addresses...</div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {addresses.map((addr: any) => (
                  <Card
                    key={addr.id}
                    className={`cursor-pointer border-2 transition-all relative ${
                      pickupAddressId === addr.id ? 'border-blue-500 bg-blue-50/10' : 'border-slate-200'
                    }`}
                    onClick={() => setAddress(addr.id)}
                    title={
                      <div className="flex items-center space-x-2">
                        <MapPin size={16} className={pickupAddressId === addr.id ? 'text-blue-500' : 'text-slate-400'} />
                        <span className="font-bold text-sm">{addr.tag}</span>
                      </div>
                    }
                  >
                    <p className="text-xs text-slate-600">{addr.address_line_1}</p>
                    {addr.address_line_2 && <p className="text-xs text-slate-600">{addr.address_line_2}</p>}
                    <p className="text-xs font-semibold text-slate-700 mt-2">
                      {addr.city}, {addr.state} - {addr.pincode}
                    </p>
                  </Card>
                ))}

                <Card
                  className="border-2 border-dashed border-slate-300 flex items-center justify-center cursor-pointer hover:border-blue-500 py-12"
                  onClick={() => setAddressModalOpen(true)}
                >
                  <div className="text-center space-y-1">
                    <Plus size={24} className="mx-auto text-slate-400" />
                    <span className="font-bold text-xs block text-slate-500">Create New Address</span>
                  </div>
                </Card>
              </div>
            )}

            <div className="flex justify-between mt-8">
              <Button onClick={handlePrev} icon={<ChevronLeft size={16} />}>Back</Button>
              <Button type="primary" onClick={handleNext} disabled={!pickupAddressId} className="gradient-primary-bg border-none">
                Schedule Time Slot <ChevronRight size={16} />
              </Button>
            </div>
          </div>
        )}

        {/* STEP 3: Pickup schedule slot & speed preference */}
        {currentStep === 2 && (
          <div className="space-y-6">
            <div className="text-center space-y-2">
              <h2 className="text-2xl font-bold" style={{ fontFamily: 'Outfit' }}>Select Schedule & Delivery Speed</h2>
              <p className="text-sm" style={{ color: 'var(--text-muted)' }}>Choose when we should pickup and how fast you want the clean clothes back.</p>
            </div>

            <Card className="glass-panel border-none p-6 shadow-sm">
              <h3 className="font-bold text-sm mb-4">1. Pickup Date</h3>
              <div className="grid grid-cols-3 sm:grid-cols-4 gap-3 mb-6">
                {getNextDays().map((day) => (
                  <div
                    key={day.value}
                    className={`cursor-pointer border-2 p-3 text-center rounded-xl transition-all ${
                      pickupDate === day.value ? 'border-blue-500 bg-blue-50/10' : 'border-slate-200'
                    }`}
                    onClick={() => setSchedule(day.value, pickupTimeSlot || '')}
                  >
                    <span className="block text-xs text-slate-500 font-semibold">{day.label.split(',')[0]}</span>
                    <span className="block font-bold text-sm mt-1">{day.label.split(',')[1]}</span>
                  </div>
                ))}
              </div>

              <h3 className="font-bold text-sm mb-4">2. Pickup Time Slot</h3>
              <div className="grid grid-cols-2 sm:grid-cols-5 gap-3 mb-6">
                {timeSlots.map((slot) => (
                  <div
                    key={slot}
                    className={`cursor-pointer border-2 p-3 text-center rounded-xl transition-all ${
                      pickupTimeSlot === slot ? 'border-blue-500 bg-blue-50/10' : 'border-slate-200'
                    }`}
                    onClick={() => setSchedule(pickupDate || '', slot)}
                  >
                    <span className="block text-xs font-bold">{slot}</span>
                  </div>
                ))}
              </div>

              <h3 className="font-bold text-sm mb-4">3. Delivery Speed</h3>
              <Radio.Group
                className="w-full grid grid-cols-1 sm:grid-cols-3 gap-4"
                value={deliveryPreference}
                onChange={(e) => setDeliveryPreference(e.target.value)}
              >
                <Radio.Button value="standard" className="h-auto p-4 rounded-xl border-2 text-left w-full hover:border-blue-500">
                  <span className="block font-bold text-sm">Standard Delivery</span>
                  <span className="block text-xs text-slate-500 mt-1">Takes 3 days. Base delivery charge (₹30 or free).</span>
                </Radio.Button>
                <Radio.Button value="express" className="h-auto p-4 rounded-xl border-2 text-left w-full hover:border-blue-500">
                  <span className="block font-bold text-sm">Express Delivery</span>
                  <span className="block text-xs text-slate-500 mt-1">Returned in 24 hours. Extra ₹50 applies.</span>
                </Radio.Button>
                <Radio.Button value="same_day" className="h-auto p-4 rounded-xl border-2 text-left w-full hover:border-blue-500">
                  <span className="block font-bold text-sm">Same Day Delivery</span>
                  <span className="block text-xs text-slate-500 mt-1">Collection before 11 AM, returned tonight (+₹100).</span>
                </Radio.Button>
              </Radio.Group>
            </Card>

            <div className="flex justify-between mt-8">
              <Button onClick={handlePrev} icon={<ChevronLeft size={16} />}>Back</Button>
              <Button type="primary" onClick={handleNext} disabled={!pickupDate || !pickupTimeSlot} className="gradient-primary-bg border-none">
                Review Invoice Order <ChevronRight size={16} />
              </Button>
            </div>
          </div>
        )}

        {/* STEP 4: Review invoice and submit checkout payment */}
        {currentStep === 3 && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2 space-y-6">
              <div className="text-center space-y-1 lg:text-left">
                <h2 className="text-2xl font-bold" style={{ fontFamily: 'Outfit' }}>Review Your Order</h2>
                <p className="text-sm" style={{ color: 'var(--text-muted)' }}>Confirm laundry items and complete payment.</p>
              </div>

              {/* Basket list */}
              <Card className="glass-panel border-none shadow-sm" title={<span className="font-bold text-sm">Garment Details</span>}>
                <div className="space-y-4 max-h-[300px] overflow-y-auto pr-1">
                  {cartItems.map((item, idx) => (
                    <div key={idx} className="flex justify-between items-center py-2 border-b last:border-0 border-slate-100">
                      <div>
                        <span className="font-bold text-sm block">{item.itemName}</span>
                        <span className="text-xs text-slate-500 block">{item.serviceName} ({item.category})</span>
                      </div>
                      <div className="flex items-center space-x-6">
                        <span className="text-xs font-semibold">Qty: {item.quantity}</span>
                        <span className="font-bold text-sm text-slate-700">₹{item.price * item.quantity}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </Card>

              {/* Schedule and address recap */}
              <Card className="glass-panel border-none shadow-sm" title={<span className="font-bold text-sm">Pickup Details</span>}>
                <div className="space-y-2 text-xs">
                  <div className="flex justify-between">
                    <span className="font-semibold text-slate-500">Scheduled Date:</span>
                    <span className="font-bold text-slate-800">{new Date(pickupDate || '').toLocaleDateString('en-IN')}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="font-semibold text-slate-500">Scheduled Slot:</span>
                    <span className="font-bold text-slate-800">{pickupTimeSlot}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="font-semibold text-slate-500">Delivery Preference:</span>
                    <span className="font-bold text-slate-800 capitalize">{deliveryPreference}</span>
                  </div>
                  <div className="border-t pt-2 mt-2" style={{ borderColor: 'var(--border-color)' }}>
                    <span className="font-semibold text-slate-500 block mb-1">Pickup Address:</span>
                    <p className="text-slate-700 leading-normal">
                      {getActiveAddressObject()?.address_line_1}, {getActiveAddressObject()?.city} - {getActiveAddressObject()?.pincode}
                    </p>
                  </div>
                </div>
              </Card>
            </div>

            {/* Price invoice Breakdown sidebar column */}
            <div className="lg:col-span-1 space-y-6">
              <Card className="glass-panel border-none shadow-md" title={<span className="font-bold text-sm">Price Breakdown</span>}>
                <div className="space-y-4">
                  {/* Coupon application block */}
                  <div className="space-y-2 pb-4 border-b" style={{ borderColor: 'var(--border-color)' }}>
                    <span className="text-xs font-bold text-slate-500 block">Apply Discount Code</span>
                    <div className="flex space-x-2">
                      <Input
                        placeholder="e.g. WELCOME50"
                        className="rounded-lg h-9 font-bold"
                        value={couponCodeInput}
                        onChange={(e) => setCouponCodeInput(e.target.value)}
                        disabled={!!coupon}
                      />
                      {coupon ? (
                        <Button danger onClick={() => setCoupon(null)} className="h-9">Remove</Button>
                      ) : (
                        <Button type="primary" onClick={handleApplyCoupon} loading={validatingCoupon} className="gradient-primary-bg border-none h-9">
                          Apply
                        </Button>
                      )}
                    </div>
                    {coupon && (
                      <Alert
                        message={<span className="text-xs">Coupon code <strong>{coupon.code}</strong> applied!</span>}
                        type="success"
                        className="p-1 px-2 border-none mt-1"
                      />
                    )}
                  </div>

                  <div className="space-y-2 text-xs">
                    <div className="flex justify-between">
                      <span>Items Subtotal:</span>
                      <span className="font-semibold">₹{getSubtotal()}</span>
                    </div>
                    {coupon && (
                      <div className="flex justify-between text-green-600">
                        <span>Discount Coupon:</span>
                        <span>- ₹{coupon.discount_amount}</span>
                      </div>
                    )}
                    <div className="flex justify-between">
                      <span>Delivery Charges:</span>
                      <span>₹{getDeliveryCharges()}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Service Tax (18% GST):</span>
                      <span>₹{getTax()}</span>
                    </div>
                    <div className="flex justify-between text-base font-extrabold text-slate-800 pt-2 border-t" style={{ borderColor: 'var(--border-color)' }}>
                      <span>Grand Total:</span>
                      <span style={{ color: 'var(--primary-color)' }}>₹{getGrandTotal()}</span>
                    </div>
                  </div>

                  <div className="space-y-2 pt-4 border-t" style={{ borderColor: 'var(--border-color)' }}>
                    <Button
                      type="primary"
                      block
                      className="gradient-primary-bg border-none h-11 text-xs font-bold"
                      onClick={() => handleCheckoutSubmit('razorpay')}
                    >
                      Pay Online (UPI / Card)
                    </Button>
                    <Button block className="h-11 text-xs font-bold" onClick={() => handleCheckoutSubmit('cod')}>
                      Cash on Delivery (COD)
                    </Button>
                  </div>
                </div>
              </Card>

              <Button block onClick={handlePrev}>Back to Schedule</Button>
            </div>
          </div>
        )}
      </div>

      {/* Quick Address Modal */}
      <Modal
        title="Add Pickup Address"
        open={addressModalOpen}
        onCancel={() => setAddressModalOpen(false)}
        footer={null}
      >
        <Form form={addressForm} layout="vertical" onFinish={(values) => createAddressMutation.mutate(values)} requiredMark={false}>
          <Form.Item label="Address Tag" name="tag" rules={[{ required: true }]}>
            <Select placeholder="Select Tag">
              <Select.Option value="Home">Home</Select.Option>
              <Select.Option value="Work">Work</Select.Option>
              <Select.Option value="Other">Other</Select.Option>
            </Select>
          </Form.Item>

          <Form.Item label="Address Line 1" name="address_line_1" rules={[{ required: true }]}>
            <Input placeholder="Flat, Street name" />
          </Form.Item>

          <Form.Item label="Address Line 2 (Optional)" name="address_line_2">
            <Input placeholder="Landmark, Area details" />
          </Form.Item>

          <div className="grid grid-cols-2 gap-4">
            <Form.Item label="City" name="city" rules={[{ required: true }]}>
              <Input placeholder="e.g. Noida" />
            </Form.Item>
            <Form.Item label="State" name="state" rules={[{ required: true }]}>
              <Input placeholder="e.g. Uttar Pradesh" />
            </Form.Item>
          </div>

          <Form.Item label="Pincode" name="pincode" rules={[{ required: true }]}>
            <Input placeholder="e.g. 201301" maxLength={6} />
          </Form.Item>

          <Form.Item name="is_default" valuePropName="checked">
            <Select placeholder="Set as Default Address?">
              <Select.Option value={true}>Set as Default</Select.Option>
              <Select.Option value={false}>Normal Address</Select.Option>
            </Select>
          </Form.Item>

          <Form.Item className="mb-0 text-right">
            <Space>
              <Button onClick={() => setAddressModalOpen(false)}>Cancel</Button>
              <Button type="primary" htmlType="submit" className="gradient-primary-bg border-none" loading={createAddressMutation.isPending}>
                Save Address
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
