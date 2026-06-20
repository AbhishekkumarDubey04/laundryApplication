import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Card, Button, Table, Select, Tag, Input, Space, Badge, message, Row, Col } from 'antd';
import {
  Sparkles,
  Search,
  Settings,
  ShieldCheck,
  TrendingUp,
  DollarSign,
  Activity,
  UserCheck,
  IndianRupee,
  LogOut,
  Calendar,
  Tag as TagIcon
} from 'lucide-react';
import api from '../services/api.ts';
import useAuthStore from '../store/useAuthStore.ts';

const LIFECYCLE_STATUSES = [
  { key: 'created', label: 'Order Created' },
  { key: 'pickup_scheduled', label: 'Pickup Scheduled' },
  { key: 'pickup_completed', label: 'Pickup Completed' },
  { key: 'processing', label: 'Processing' },
  { key: 'washing', label: 'Washing' },
  { key: 'drying', label: 'Drying' },
  { key: 'ironing', label: 'Steam Ironing' },
  { key: 'quality_check', label: 'Quality Check' },
  { key: 'ready_for_delivery', label: 'Ready for Delivery' },
  { key: 'out_for_delivery', label: 'Out for Delivery' },
  { key: 'delivered', label: 'Delivered' }
];

export default function AdminDashboard() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const logout = useAuthStore((state) => state.logout);

  const [searchText, setSearchText] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');

  // Queries
  const { data: stats = {}, isLoading: statsLoading } = useQuery({
    queryKey: ['admin/stats'],
    queryFn: async () => {
      const res = await api.get('/admin/dashboard-stats');
      return res.data;
    }
  });

  const { data: orders = [], isLoading: ordersLoading } = useQuery({
    queryKey: ['admin/orders'],
    queryFn: async () => {
      const res = await api.get('/orders'); // Admin sees all
      return res.data;
    }
  });

  // Mutations
  const updateStatusMutation = useMutation({
    mutationFn: async ({ id, status }: { id: number; status: string }) => {
      const res = await api.put(`/orders/${id}/status`, { status });
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin/orders'] });
      queryClient.invalidateQueries({ queryKey: ['admin/stats'] });
      message.success('Order status updated');
    }
  });

  const updatePaymentMutation = useMutation({
    mutationFn: async ({ id, payment_status }: { id: number; payment_status: string }) => {
      const res = await api.put(`/orders/${id}/payment-status`, { payment_status });
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin/orders'] });
      queryClient.invalidateQueries({ queryKey: ['admin/stats'] });
      message.success('Payment status updated');
    }
  });

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  // Filter orders by search term and status
  const filteredOrders = orders.filter((o: any) => {
    const matchesSearch =
      o.id.toString().includes(searchText) ||
      o.user_name?.toLowerCase().includes(searchText.toLowerCase()) ||
      o.user_phone?.includes(searchText);

    const matchesStatus = statusFilter === 'all' || o.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'created': return 'blue';
      case 'pickup_scheduled': return 'orange';
      case 'pickup_completed': return 'cyan';
      case 'processing': return 'purple';
      case 'washing': case 'drying': case 'ironing': return 'geekblue';
      case 'ready_for_delivery': return 'success';
      case 'out_for_delivery': return 'warning';
      case 'delivered': return 'green';
      default: return 'default';
    }
  };

  return (
    <div className="min-h-screen pb-16" style={{ backgroundColor: 'var(--bg-primary)' }}>
      {/* Admin header */}
      <div className="glass-panel sticky top-0 z-40 rounded-none border-b bg-white" style={{ borderBottom: '1px solid var(--border-color)' }}>
        <div className="max-w-7xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center space-x-6">
            <div className="flex items-center space-x-2 cursor-pointer" onClick={() => navigate('/')}>
              <div className="h-9 w-9 rounded-xl gradient-primary-bg flex items-center justify-center text-white font-extrabold shadow-sm">
                L
              </div>
              <span className="font-bold text-lg" style={{ color: 'var(--primary-color)' }}>LaundryIndia</span>
            </div>
            
            <nav className="hidden sm:flex items-center space-x-6 text-sm">
              <Button type="link" onClick={() => navigate('/admin')} className="font-bold p-0">Dashboard</Button>
              <Button type="text" onClick={() => navigate('/admin/pricing')} className="font-semibold text-slate-600">Rates Config</Button>
              <Button type="text" onClick={() => navigate('/admin/coupons')} className="font-semibold text-slate-600">Discount Coupons</Button>
            </nav>
          </div>

          <div className="flex items-center space-x-4">
            <Tag color="red" className="font-semibold text-xs tracking-wider uppercase">Admin Portal</Tag>
            <Button
              type="text"
              icon={<LogOut size={16} />}
              onClick={handleLogout}
              className="text-red-500 hover:text-red-700 flex items-center justify-center"
            >
              Logout
            </Button>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 mt-8 space-y-8">
        
        {/* KPI statistics cards row */}
        <Row gutter={[24, 24]}>
          <Col xs={24} sm={12} lg={4}>
            <Card className="glass-panel border-none shadow-sm" loading={statsLoading}>
              <span className="text-xs font-semibold block" style={{ color: 'var(--text-muted)' }}>TODAY'S ORDERS</span>
              <span className="text-2xl font-extrabold tracking-tight mt-1 block">{stats.todayOrders || 0}</span>
            </Card>
          </Col>
          <Col xs={24} sm={12} lg={5}>
            <Card className="glass-panel border-none shadow-sm" loading={statsLoading}>
              <span className="text-xs font-semibold block" style={{ color: 'var(--text-muted)' }}>TODAY'S REVENUE</span>
              <span className="text-2xl font-extrabold tracking-tight mt-1 block text-green-600">₹{stats.todayRevenue || '0.00'}</span>
            </Card>
          </Col>
          <Col xs={24} sm={12} lg={5}>
            <Card className="glass-panel border-none shadow-sm" loading={statsLoading}>
              <span className="text-xs font-semibold block" style={{ color: 'var(--text-muted)' }}>PENDING QUEUE</span>
              <span className="text-2xl font-extrabold tracking-tight mt-1 block text-orange-600">{stats.pendingOrders || 0}</span>
            </Card>
          </Col>
          <Col xs={24} sm={12} lg={5}>
            <Card className="glass-panel border-none shadow-sm" loading={statsLoading}>
              <span className="text-xs font-semibold block" style={{ color: 'var(--text-muted)' }}>TOTAL CUSTOMERS</span>
              <span className="text-2xl font-extrabold tracking-tight mt-1 block text-blue-600">{stats.totalCustomers || 0}</span>
            </Card>
          </Col>
          <Col xs={24} sm={12} lg={5}>
            <Card className="glass-panel border-none shadow-sm" loading={statsLoading}>
              <span className="text-xs font-semibold block" style={{ color: 'var(--text-muted)' }}>AVG ORDER VALUE</span>
              <span className="text-2xl font-extrabold tracking-tight mt-1 block">₹{(stats.averageOrderValue || 0).toFixed(2)}</span>
            </Card>
          </Col>
        </Row>

        {/* Search, Filter controls & Table list */}
        <Card className="glass-panel border-none shadow-md" title={<span className="font-bold text-sm">Customer Bookings Directory</span>} extra={
          <Space>
            <Input
              prefix={<Search size={16} className="text-slate-400 mr-2" />}
              placeholder="ID, Customer, Phone"
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              className="rounded-lg h-9 w-48"
            />
            <Select
              value={statusFilter}
              onChange={(val) => setStatusFilter(val)}
              className="h-9 w-40"
            >
              <Select.Option value="all">All Statuses</Select.Option>
              {LIFECYCLE_STATUSES.map((s) => (
                <Select.Option key={s.key} value={s.key}>{s.label}</Select.Option>
              ))}
            </Select>
          </Space>
        }>
          <Table
            dataSource={filteredOrders}
            rowKey="id"
            loading={ordersLoading}
            columns={[
              {
                title: 'Order ID',
                dataIndex: 'id',
                key: 'id',
                render: (id) => <strong className="text-blue-600">#{id}</strong>
              },
              {
                title: 'Customer Details',
                key: 'customer',
                render: (_, record: any) => (
                  <div>
                    <span className="font-bold text-xs block">{record.user_name}</span>
                    <span className="text-[10px] text-slate-500 block">{record.user_phone}</span>
                  </div>
                )
              },
              {
                title: 'Pickup Schedule',
                key: 'pickup',
                render: (_, record: any) => (
                  <div>
                    <span className="font-semibold text-xs block">{new Date(record.pickup_date).toLocaleDateString('en-IN')}</span>
                    <span className="text-[10px] text-slate-500 block">{record.pickup_time_slot}</span>
                  </div>
                )
              },
              {
                title: 'Status',
                dataIndex: 'status',
                key: 'status',
                render: (status, record: any) => (
                  <Select
                    size="small"
                    value={status}
                    onChange={(val) => updateStatusMutation.mutate({ id: record.id, status: val })}
                    className="w-40"
                  >
                    {LIFECYCLE_STATUSES.map((s) => (
                      <Select.Option key={s.key} value={s.key}>{s.label}</Select.Option>
                    ))}
                  </Select>
                )
              },
              {
                title: 'Payment Info',
                key: 'payment',
                render: (_, record: any) => (
                  <Space size="small">
                    <Select
                      size="small"
                      value={record.payment_status}
                      onChange={(val) => updatePaymentMutation.mutate({ id: record.id, payment_status: val })}
                      className="w-28"
                    >
                      <Select.Option value="pending">Pending</Select.Option>
                      <Select.Option value="paid">Paid</Select.Option>
                      <Select.Option value="failed">Failed</Select.Option>
                      <Select.Option value="refunded">Refunded</Select.Option>
                    </Select>
                    <span className="text-[10px] font-semibold text-slate-500 uppercase">{record.payment_gateway}</span>
                  </Space>
                )
              },
              {
                title: 'Grand Total',
                dataIndex: 'grand_total',
                key: 'grand_total',
                render: (val) => <span className="font-bold text-slate-800">₹{val}</span>
              },
              {
                title: 'Action',
                key: 'action',
                render: (_, record: any) => (
                  <Button type="default" size="small" onClick={() => navigate(`/track/${record.id}`)}>
                    View Details
                  </Button>
                )
              }
            ]}
          />
        </Card>
      </div>
    </div>
  );
}
