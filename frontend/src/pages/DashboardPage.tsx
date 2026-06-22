import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Card, Button, Table, Modal, Form, Input, Select, Tag, Badge, message, Popconfirm, List, Space } from 'antd';
import {
  User,
  MapPin,
  Clock,
  Plus,
  Trash2,
  Calendar,
  LogOut,
  IndianRupee,
  Bell,
  CheckCircle,
  Eye,
  Settings,
  Sparkles,
  Activity,
  Home,
  ClipboardList,
  Sun,
  Moon
} from 'lucide-react';
import api from '../services/api.ts';
import useAuthStore from '../store/useAuthStore.ts';
import BookingFlow from './BookingFlow.tsx';

export default function DashboardPage() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { user, logout, isDarkMode, toggleTheme } = useAuthStore();

  const [addressModalOpen, setAddressModalOpen] = useState(false);
  const [editingAddress, setEditingAddress] = useState<any>(null);
  const [addressForm] = Form.useForm();
  const [profileForm] = Form.useForm();
  const [activeTab, setActiveTab] = useState<'home' | 'book' | 'orders' | 'profile'>('home');

  // Queries
  const { data: orders = [], isLoading: ordersLoading } = useQuery({
    queryKey: ['orders'],
    queryFn: async () => {
      const res = await api.get('/orders');
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

  const { data: notifications = [] } = useQuery({
    queryKey: ['notifications'],
    queryFn: async () => {
      const res = await api.get('/notifications');
      return res.data;
    }
  });

  // Mutations
  const addressMutation = useMutation({
    mutationFn: async (values: any) => {
      if (editingAddress) {
        const res = await api.put(`/addresses/${editingAddress.id}`, values);
        return res.data;
      } else {
        const res = await api.post('/addresses', values);
        return res.data;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['addresses'] });
      message.success(editingAddress ? 'Address updated' : 'Address added successfully');
      setAddressModalOpen(false);
      setEditingAddress(null);
      addressForm.resetFields();
    },
    onError: () => {
      message.error('Failed to save address details.');
    }
  });

  const deleteAddressMutation = useMutation({
    mutationFn: async (id: number) => {
      await api.delete(`/addresses/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['addresses'] });
      message.success('Address deleted successfully');
    }
  });

  const profileMutation = useMutation({
    mutationFn: async (values: any) => {
      const res = await api.put('/auth/profile', values);
      return res.data;
    },
    onSuccess: () => {
      message.success('Profile settings updated');
      queryClient.invalidateQueries({ queryKey: ['auth/me'] });
    }
  });

  const readAllNotificationsMutation = useMutation({
    mutationFn: async () => {
      await api.put('/notifications/read-all');
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
    }
  });

  // Calculations for KPI Cards
  const activeOrders = orders.filter((o: any) => o.status !== 'delivered').length;
  const completedOrders = orders.filter((o: any) => o.status === 'delivered').length;
  const totalSpend = orders
    .filter((o: any) => o.payment_status === 'paid')
    .reduce((sum: number, o: any) => sum + parseFloat(o.grand_total), 0);

  const handleSaveAddress = (values: any) => {
    addressMutation.mutate(values);
  };

  const handleOpenEditAddress = (addr: any) => {
    setEditingAddress(addr);
    addressForm.setFieldsValue(addr);
    setAddressModalOpen(true);
  };

  const handleLogout = () => {
    logout();
    navigate('/');
  };

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

  const unreadNotificationsCount = notifications.filter((n: any) => n.status === 'unread').length;

  return (
    <div className="min-h-screen pb-24" style={{ backgroundColor: 'var(--bg-primary)' }}>
      {/* Header Bar */}
      <div className="glass-panel sticky top-0 z-40 rounded-none border-b border-slate-200 bg-white" style={{ borderBottom: '1px solid var(--border-color)' }}>
        <div className="max-w-7xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center space-x-2 cursor-pointer" onClick={() => { setActiveTab('home'); navigate('/dashboard'); }}>
            <div className="h-9 w-9 rounded-xl gradient-primary-bg flex items-center justify-center text-white font-extrabold shadow-sm">
              L
            </div>
            <span className="font-bold text-lg" style={{ color: 'var(--primary-color)' }}>LaundryIndia</span>
          </div>

          <div className="flex items-center space-x-3">
            <Button
              type="text"
              icon={isDarkMode ? <Sun size={18} className="text-yellow-500" /> : <Moon size={18} className="text-slate-600" />}
              onClick={toggleTheme}
              className="flex items-center justify-center hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg"
            />
            <Button
              type="text"
              icon={<LogOut size={18} />}
              onClick={handleLogout}
              className="flex items-center justify-center text-red-500 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-950/30 rounded-lg font-medium"
            >
              <span className="hidden sm:inline ml-1">Logout</span>
            </Button>
          </div>
        </div>
      </div>

      {/* Main Content Area */}
      <div className="max-w-7xl mx-auto px-4 mt-8">
        
        {/* Render HOME tab */}
        {activeTab === 'home' && (
          <div className="space-y-6 animate-fade-in">
            {/* KPI Dashboard Summary Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
              <Card className="glass-panel border-none shadow-sm gradient-premium-card">
                <div className="flex items-center justify-between">
                  <div>
                    <span className="text-xs font-semibold block" style={{ color: 'var(--text-muted)' }}>ACTIVE BOOKINGS</span>
                    <span className="text-3xl font-extrabold tracking-tight mt-1 block">{activeOrders}</span>
                  </div>
                  <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-600">
                    <Activity size={20} />
                  </div>
                </div>
              </Card>

              <Card className="glass-panel border-none shadow-sm">
                <div className="flex items-center justify-between">
                  <div>
                    <span className="text-xs font-semibold block" style={{ color: 'var(--text-muted)' }}>COMPLETED DELIVERIES</span>
                    <span className="text-3xl font-extrabold tracking-tight mt-1 block text-green-600">{completedOrders}</span>
                  </div>
                  <div className="h-10 w-10 rounded-full bg-green-100 flex items-center justify-center text-green-600">
                    <CheckCircle size={20} />
                  </div>
                </div>
              </Card>

              <Card className="glass-panel border-none shadow-sm">
                <div className="flex items-center justify-between">
                  <div>
                    <span className="text-xs font-semibold block" style={{ color: 'var(--text-muted)' }}>WALLET BALANCE</span>
                    <span className="text-3xl font-extrabold tracking-tight mt-1 block text-blue-600">₹0.00</span>
                  </div>
                  <div className="h-10 w-10 rounded-full bg-yellow-100 flex items-center justify-center text-yellow-600">
                    <IndianRupee size={20} />
                  </div>
                </div>
              </Card>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
              {/* Account Summary */}
              <div className="lg:col-span-1">
                <Card className="glass-panel border-none shadow-md" title={<span className="font-bold text-sm">Account Overview</span>}>
                  <div className="flex flex-col items-center space-y-3 pb-4 border-b" style={{ borderColor: 'var(--border-color)' }}>
                    <div className="h-16 w-16 rounded-full gradient-primary-bg flex items-center justify-center text-white text-2xl font-bold">
                      {user?.name[0]}
                    </div>
                    <h3 className="font-bold text-lg text-center">{user?.name}</h3>
                    <Tag color="blue" className="uppercase font-semibold text-xs tracking-wider">{user?.role}</Tag>
                    <span className="text-sm" style={{ color: 'var(--text-muted)' }}>{user?.phone}</span>
                  </div>

                  <div className="pt-4 space-y-2">
                    <div className="flex justify-between text-xs">
                      <span style={{ color: 'var(--text-muted)' }}>Registered Email:</span>
                      <span className="font-semibold">{user?.email || 'Not configured'}</span>
                    </div>
                    <div className="flex justify-between text-xs">
                      <span style={{ color: 'var(--text-muted)' }}>Total Paid Spend:</span>
                      <span className="font-semibold text-green-600">₹{totalSpend.toFixed(2)}</span>
                    </div>
                  </div>
                </Card>
              </div>

              {/* Notifications */}
              <div className="lg:col-span-2">
                <Card className="glass-panel border-none shadow-md" title={
                  <div className="flex justify-between items-center">
                    <span className="flex items-center space-x-2 font-bold text-sm">
                      <Bell size={16} />
                      <span>Recent Alerts</span>
                      {unreadNotificationsCount > 0 && <Badge count={unreadNotificationsCount} />}
                    </span>
                    {unreadNotificationsCount > 0 && (
                      <Button type="link" size="small" className="p-0" onClick={() => readAllNotificationsMutation.mutate()}>
                        Mark read
                      </Button>
                    )}
                  </div>
                }>
                  <List
                    itemLayout="horizontal"
                    dataSource={notifications.slice(0, 5)}
                    locale={{ emptyText: 'No alerts found' }}
                    renderItem={(n: any) => (
                      <List.Item className="p-2 border-b last:border-b-0" style={{ padding: '8px 0px', borderColor: 'var(--border-color)' }}>
                        <List.Item.Meta
                          title={<span className={`text-xs ${n.status === 'unread' ? 'font-bold' : ''}`}>{n.title}</span>}
                          description={
                            <div className="space-y-1">
                              <p className="text-xs" style={{ color: 'var(--text-muted)' }}>{n.message}</p>
                              <span className="text-[10px] block" style={{ color: 'var(--text-muted)' }}>
                                {new Date(n.created_at).toLocaleDateString('en-IN', { hour: '2-digit', minute: '2-digit' })}
                              </span>
                            </div>
                          }
                        />
                      </List.Item>
                    )}
                  />
                </Card>
              </div>
            </div>
          </div>
        )}

        {/* Render BOOK tab (Inline booking stepper flow) */}
        {activeTab === 'book' && (
          <div className="animate-fade-in">
            <BookingFlow inlined={true} onClose={() => setActiveTab('home')} />
          </div>
        )}

        {/* Render ORDERS tab (Order history list) */}
        {activeTab === 'orders' && (
          <div className="animate-fade-in">
            <Card className="glass-panel border-none shadow-md" title={<span className="font-bold text-sm">Order History & Tracking</span>}>
              <Table
                dataSource={orders}
                rowKey="id"
                loading={ordersLoading}
                pagination={{ pageSize: 8 }}
                columns={[
                  {
                    title: 'Order ID',
                    dataIndex: 'id',
                    key: 'id',
                    render: (id) => <strong className="text-blue-600">#{id}</strong>
                  },
                  {
                    title: 'Pickup Date',
                    dataIndex: 'pickup_date',
                    key: 'pickup_date',
                    render: (d) => new Date(d).toLocaleDateString('en-IN')
                  },
                  {
                    title: 'Delivery Mode',
                    dataIndex: 'delivery_preference',
                    key: 'delivery_preference',
                    render: (pref) => <span className="capitalize">{pref}</span>
                  },
                  {
                    title: 'Status',
                    dataIndex: 'status',
                    key: 'status',
                    render: (status) => (
                      <Tag color={getStatusColor(status)}>
                        {status.replace(/_/g, ' ').toUpperCase()}
                      </Tag>
                    )
                  },
                  {
                    title: 'Amount',
                    dataIndex: 'grand_total',
                    key: 'grand_total',
                    render: (total) => <span className="font-semibold text-slate-800">₹{total}</span>
                  },
                  {
                    title: 'Action',
                    key: 'action',
                    render: (_, record: any) => (
                      <Button
                        type="default"
                        icon={<Eye size={14} />}
                        onClick={() => navigate(`/track/${record.id}`)}
                        className="flex items-center space-x-1 hover:border-blue-500"
                      >
                        Track
                      </Button>
                    )
                  }
                ]}
              />
            </Card>
          </div>
        )}

        {/* Render PROFILE tab (Profile form & Address book) */}
        {activeTab === 'profile' && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 animate-fade-in">
            {/* Profile Config */}
            <Card className="glass-panel border-none shadow-md" title={<span className="font-bold text-sm">Profile Details</span>}>
              <Form
                form={profileForm}
                layout="vertical"
                initialValues={{ name: user?.name, email: user?.email }}
                onFinish={(values) => profileMutation.mutate(values)}
                requiredMark={false}
                className="mt-2"
              >
                <Form.Item label="Contact Name" name="name" rules={[{ required: true }]}>
                  <Input placeholder="Enter your name" className="h-10" />
                </Form.Item>
                <Form.Item label="Email Address" name="email">
                  <Input placeholder="Enter your email" type="email" className="h-10" />
                </Form.Item>
                <Form.Item>
                  <Button type="primary" htmlType="submit" className="gradient-primary-bg border-none" loading={profileMutation.isPending}>
                    Save Changes
                  </Button>
                </Form.Item>
              </Form>
            </Card>

            {/* Address Manager */}
            <Card className="glass-panel border-none shadow-md" title={
              <div className="flex justify-between items-center w-full">
                <span className="font-bold text-sm">Address Book</span>
                <Button
                  type="primary"
                  size="small"
                  icon={<Plus size={14} />}
                  onClick={() => {
                    setEditingAddress(null);
                    addressForm.resetFields();
                    setAddressModalOpen(true);
                  }}
                  className="gradient-primary-bg border-none flex items-center"
                >
                  Add
                </Button>
              </div>
            }>
              <div className="grid grid-cols-1 gap-4 max-h-[450px] overflow-y-auto pr-1">
                {addresses.map((addr: any) => (
                  <Card
                    key={addr.id}
                    className="border border-slate-200 relative hover:border-blue-500 transition-colors"
                    title={
                      <div className="flex items-center space-x-2">
                        <MapPin size={16} className="text-blue-500" />
                        <span className="font-bold text-sm">{addr.tag}</span>
                        {addr.is_default && <Tag color="green" className="text-[10px]">Default</Tag>}
                      </div>
                    }
                    extra={
                      <Space>
                        <Button type="link" size="small" className="p-0" onClick={() => handleOpenEditAddress(addr)}>Edit</Button>
                        <Popconfirm
                          title="Delete this address?"
                          onConfirm={() => deleteAddressMutation.mutate(addr.id)}
                          okText="Yes"
                          cancelText="No"
                        >
                          <Button type="text" danger size="small" icon={<Trash2 size={14} />}></Button>
                        </Popconfirm>
                      </Space>
                    }
                  >
                    <p className="text-xs text-slate-600">{addr.address_line_1}</p>
                    {addr.address_line_2 && <p className="text-xs text-slate-600">{addr.address_line_2}</p>}
                    <p className="text-xs font-semibold text-slate-700 mt-2">
                      {addr.city}, {addr.state} - {addr.pincode}
                    </p>
                  </Card>
                ))}
                {addresses.length === 0 && (
                  <div className="text-center py-8 text-slate-400">
                    No addresses saved yet. Add one to begin bookings.
                  </div>
                )}
              </div>
            </Card>
          </div>
        )}
      </div>

      {/* Floating Bottom Navigation Bar */}
      <div className="fixed bottom-0 left-0 right-0 sm:bottom-6 sm:left-1/2 sm:-translate-x-1/2 z-50 px-0 sm:px-4 sm:max-w-md w-full">
        <div className="bg-white/95 dark:bg-[#1E2024]/95 border-t sm:border border-slate-200/80 dark:border-slate-800/80 shadow-2xl rounded-t-2xl sm:rounded-full py-3 px-8 flex justify-between items-center backdrop-blur-md">
          <button
            onClick={() => setActiveTab('home')}
            className={`flex flex-col items-center justify-center space-y-1 bg-transparent border-none outline-none cursor-pointer transition-colors duration-200 ${
              activeTab === 'home' ? 'text-[#FF6B00]' : 'text-slate-400 hover:text-slate-600 dark:hover:text-slate-200'
            }`}
          >
            <Home size={20} className={activeTab === 'home' ? 'stroke-[2.5]' : 'stroke-[1.5]'} />
            <span className="text-[10px] font-semibold">Home</span>
          </button>

          <button
            onClick={() => setActiveTab('book')}
            className={`flex flex-col items-center justify-center space-y-1 bg-transparent border-none outline-none cursor-pointer transition-colors duration-200 ${
              activeTab === 'book' ? 'text-[#FF6B00]' : 'text-slate-400 hover:text-slate-600 dark:hover:text-slate-200'
            }`}
          >
            <Sparkles size={20} className={activeTab === 'book' ? 'stroke-[2.5]' : 'stroke-[1.5]'} />
            <span className="text-[10px] font-semibold">Book</span>
          </button>

          <button
            onClick={() => setActiveTab('orders')}
            className={`flex flex-col items-center justify-center space-y-1 bg-transparent border-none outline-none cursor-pointer transition-colors duration-200 ${
              activeTab === 'orders' ? 'text-[#FF6B00]' : 'text-slate-400 hover:text-slate-600 dark:hover:text-slate-200'
            }`}
          >
            <ClipboardList size={20} className={activeTab === 'orders' ? 'stroke-[2.5]' : 'stroke-[1.5]'} />
            <span className="text-[10px] font-semibold">Orders</span>
          </button>

          <button
            onClick={() => setActiveTab('profile')}
            className={`flex flex-col items-center justify-center space-y-1 bg-transparent border-none outline-none cursor-pointer transition-colors duration-200 ${
              activeTab === 'profile' ? 'text-[#FF6B00]' : 'text-slate-400 hover:text-slate-600 dark:hover:text-slate-200'
            }`}
          >
            <User size={20} className={activeTab === 'profile' ? 'stroke-[2.5]' : 'stroke-[1.5]'} />
            <span className="text-[10px] font-semibold">Profile</span>
          </button>
        </div>
      </div>

      {/* Address creation/edit modal */}
      <Modal
        title={editingAddress ? 'Update Address' : 'Create New Address'}
        open={addressModalOpen}
        onCancel={() => {
          setAddressModalOpen(false);
          setEditingAddress(null);
          addressForm.resetFields();
        }}
        footer={null}
      >
        <Form form={addressForm} layout="vertical" onFinish={handleSaveAddress} requiredMark={false}>
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
              <Button type="primary" htmlType="submit" className="gradient-primary-bg border-none" loading={addressMutation.isPending}>
                Save Address
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
