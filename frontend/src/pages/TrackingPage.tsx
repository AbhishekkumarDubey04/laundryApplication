import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Card, Button, Steps, Tag, Table, Alert, Space, message, Select } from 'antd';
import {
  ArrowLeft,
  Calendar,
  MapPin,
  Clock,
  IndianRupee,
  ShieldCheck,
  CheckCircle,
  Truck,
  Sparkles,
  Info
} from 'lucide-react';
import api from '../services/api.ts';
import useAuthStore from '../store/useAuthStore.ts';

const { Step } = Steps;

const LIFECYCLE_STATUSES = [
  { key: 'created', label: 'Order Created', desc: 'Order submitted to the queue.' },
  { key: 'pickup_scheduled', label: 'Pickup Scheduled', desc: 'Agent assigned to collect clothes.' },
  { key: 'pickup_completed', label: 'Pickup Completed', desc: 'Clothes collected by our agent.' },
  { key: 'processing', label: 'Processing', desc: 'Garments sorted and inspected.' },
  { key: 'washing', label: 'Washing', desc: 'Garments washing cycles in progress.' },
  { key: 'drying', label: 'Drying', desc: 'Machine drying and sorting.' },
  { key: 'ironing', label: 'Steam Ironing', desc: 'Creaseless steam pressing.' },
  { key: 'quality_check', label: 'Quality Check', desc: 'Post-press standard review.' },
  { key: 'ready_for_delivery', label: 'Ready for Delivery', desc: 'Packed and ready at hub.' },
  { key: 'out_for_delivery', label: 'Out for Delivery', desc: 'Delivery agent is on the way.' },
  { key: 'delivered', label: 'Delivered', desc: 'Clothes handed over to customer.' }
];

export default function TrackingPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { user } = useAuthStore();

  // Queries
  const { data: orderDetails, isLoading, error } = useQuery({
    queryKey: ['order', id],
    queryFn: async () => {
      const res = await api.get(`/orders/${id}`);
      return res.data;
    }
  });

  // Mutations
  const updateStatusMutation = useMutation({
    mutationFn: async (status: string) => {
      const res = await api.put(`/orders/${id}/status`, { status });
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['order', id] });
      message.success('Status updated successfully');
    },
    onError: () => {
      message.error('Failed to update status.');
    }
  });

  const updatePaymentMutation = useMutation({
    mutationFn: async (payment_status: string) => {
      const res = await api.put(`/orders/${id}/payment-status`, { payment_status });
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['order', id] });
      message.success('Payment status updated');
    }
  });

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ backgroundColor: 'var(--bg-primary)' }}>
        <span className="text-slate-400">Loading tracking logs...</span>
      </div>
    );
  }

  if (error || !orderDetails) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center" style={{ backgroundColor: 'var(--bg-primary)' }}>
        <Alert message="Order Not Found" description="The requested order ID could not be loaded." type="error" showIcon className="mb-4" />
        <Button onClick={() => navigate('/dashboard')}>Go to Dashboard</Button>
      </div>
    );
  }

  const { order, items } = orderDetails;

  // Calculate index of active status in timeline
  const activeIndex = LIFECYCLE_STATUSES.findIndex((s) => s.key === order.status);

  const getStatusTagColor = (status: string) => {
    if (status === 'delivered') return 'green';
    if (status === 'created') return 'blue';
    return 'orange';
  };

  return (
    <div className="min-h-screen pb-16" style={{ backgroundColor: 'var(--bg-primary)' }}>
      {/* Header Bar */}
      <div className="glass-panel sticky top-0 z-40 rounded-none border-b bg-white" style={{ borderBottom: '1px solid var(--border-color)' }}>
        <div className="max-w-6xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center space-x-2 cursor-pointer" onClick={() => navigate(user?.role === 'admin' ? '/admin' : '/dashboard')}>
            <ArrowLeft size={18} className="text-slate-700" />
            <span className="font-bold text-sm">Back to Dashboard</span>
          </div>
          <span className="font-bold text-sm">Order #{order.id} Tracking</span>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-4 mt-8 grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Timeline block */}
        <div className="lg:col-span-2 space-y-6">
          <Card className="glass-panel border-none shadow-md" title={
            <div className="flex justify-between items-center w-full">
              <span className="font-bold text-sm">Order Progress Tracker</span>
              <Tag color={getStatusTagColor(order.status)} className="capitalize font-semibold text-xs">
                {order.status.replace(/_/g, ' ')}
              </Tag>
            </div>
          }>
            <Steps
              direction="vertical"
              current={activeIndex}
              size="small"
              className="pl-4 pt-2"
            >
              {LIFECYCLE_STATUSES.map((status) => (
                <Step
                  key={status.key}
                  title={<span className="font-bold text-sm">{status.label}</span>}
                  description={
                    <span className="text-xs block pb-4" style={{ color: 'var(--text-muted)' }}>
                      {status.desc}
                    </span>
                  }
                />
              ))}
            </Steps>
          </Card>
        </div>

        {/* Invoice details & Admin override config */}
        <div className="lg:col-span-1 space-y-6">
          {/* Admin Operations console */}
          {user?.role === 'admin' && (
            <Card className="glass-panel border-none shadow-md bg-yellow-50/5 border-yellow-200" title={<span className="font-bold text-sm text-yellow-800">Admin Controls</span>}>
              <div className="space-y-4">
                <div className="space-y-1">
                  <span className="text-xs font-bold text-slate-500 block">Override Lifecycle Status</span>
                  <Select
                    className="w-full h-10"
                    value={order.status}
                    onChange={(val) => updateStatusMutation.mutate(val)}
                  >
                    {LIFECYCLE_STATUSES.map((s) => (
                      <Select.Option key={s.key} value={s.key}>{s.label}</Select.Option>
                    ))}
                  </Select>
                </div>

                <div className="space-y-1">
                  <span className="text-xs font-bold text-slate-500 block">Override Payment Status</span>
                  <Select
                    className="w-full h-10"
                    value={order.payment_status}
                    onChange={(val) => updatePaymentMutation.mutate(val)}
                  >
                    <Select.Option value="pending">Pending</Select.Option>
                    <Select.Option value="paid">Paid</Select.Option>
                    <Select.Option value="failed">Failed</Select.Option>
                    <Select.Option value="refunded">Refunded</Select.Option>
                  </Select>
                </div>

                <Alert
                  message={<span className="text-xs">Select options above to simulate status changes instantly.</span>}
                  type="warning"
                  showIcon
                  icon={<Info size={14} />}
                  className="p-1 px-2 border-none"
                />
              </div>
            </Card>
          )}

          {/* Invoice Summary */}
          <Card className="glass-panel border-none shadow-md" title={<span className="font-bold text-sm">Invoice Details</span>}>
            <div className="space-y-4">
              <div className="space-y-1 text-xs">
                <div className="flex justify-between">
                  <span style={{ color: 'var(--text-muted)' }}>Customer Name:</span>
                  <span className="font-semibold">{order.user_name}</span>
                </div>
                <div className="flex justify-between">
                  <span style={{ color: 'var(--text-muted)' }}>Customer Mobile:</span>
                  <span className="font-semibold">{order.user_phone}</span>
                </div>
                <div className="flex justify-between">
                  <span style={{ color: 'var(--text-muted)' }}>Estimated Delivery:</span>
                  <span className="font-semibold text-blue-600">
                    {new Date(order.delivery_date).toLocaleDateString('en-IN')}
                  </span>
                </div>
              </div>

              <div className="border-t pt-4" style={{ borderColor: 'var(--border-color)' }}>
                <span className="text-xs font-bold block mb-2">Garment Cart Summary</span>
                <div className="space-y-2 max-h-[150px] overflow-y-auto pr-1">
                  {items.map((item: any) => (
                    <div key={item.id} className="flex justify-between text-xs py-1 border-b last:border-b-0 border-slate-100">
                      <span>{item.item_name} × {item.quantity} ({item.service_name})</span>
                      <span className="font-semibold text-slate-700">₹{item.total_price}</span>
                    </div>
                  ))}
                </div>
              </div>

              <div className="border-t pt-4 space-y-2 text-xs" style={{ borderColor: 'var(--border-color)' }}>
                <div className="flex justify-between">
                  <span>Subtotal Amount:</span>
                  <span className="font-semibold">₹{order.total_amount}</span>
                </div>
                {parseFloat(order.discount_amount) > 0 && (
                  <div className="flex justify-between text-green-600">
                    <span>Coupon Discount ({order.coupon_code}):</span>
                    <span>- ₹{order.discount_amount}</span>
                  </div>
                )}
                <div className="flex justify-between">
                  <span>Pickup & Delivery Charge:</span>
                  <span>₹{order.delivery_charges}</span>
                </div>
                <div className="flex justify-between">
                  <span>GST Tax (18%):</span>
                  <span>₹{order.tax_amount}</span>
                </div>
                <div className="flex justify-between text-sm font-extrabold pt-2 border-t" style={{ borderColor: 'var(--border-color)', color: 'var(--primary-color)' }}>
                  <span>Grand Total Paid:</span>
                  <span>₹{order.grand_total}</span>
                </div>
                <div className="flex justify-between pt-2">
                  <span>Payment Gateway:</span>
                  <span className="uppercase font-semibold">{order.payment_gateway || 'Razorpay'}</span>
                </div>
                <div className="flex justify-between">
                  <span>Payment Status:</span>
                  <Tag color={order.payment_status === 'paid' ? 'green' : 'orange'} className="m-0 font-semibold text-[10px]">
                    {order.payment_status.toUpperCase()}
                  </Tag>
                </div>
              </div>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}
