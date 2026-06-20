import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Card, Button, Table, Modal, Form, Input, InputNumber, Select, Space, Popconfirm, Tag, message } from 'antd';
import { ArrowLeft, Plus, Trash2, Tag as TagIcon, Percent } from 'lucide-react';
import api from '../services/api.ts';

export default function AdminCoupons() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const [modalOpen, setModalOpen] = useState(false);
  const [editingCoupon, setEditingCoupon] = useState<any>(null);
  const [form] = Form.useForm();

  // Queries
  const { data: coupons = [], isLoading: couponsLoading } = useQuery({
    queryKey: ['admin/coupons'],
    queryFn: async () => {
      const res = await api.get('/coupons');
      return res.data;
    }
  });

  // Mutations
  const saveCouponMutation = useMutation({
    mutationFn: async (values: any) => {
      // Expiration date formatted with ISO string
      const payload = {
        ...values,
        expiry_date: new Date(values.expiry_date).toISOString()
      };
      if (editingCoupon) {
        const res = await api.put(`/coupons/${editingCoupon.id}`, payload);
        return res.data;
      } else {
        const res = await api.post('/coupons', payload);
        return res.data;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin/coupons'] });
      message.success(editingCoupon ? 'Coupon updated' : 'Coupon created successfully');
      setModalOpen(false);
      setEditingCoupon(null);
      form.resetFields();
    },
    onError: (err: any) => {
      message.error(err.response?.data?.error || 'Failed to save coupon details.');
    }
  });

  const deleteCouponMutation = useMutation({
    mutationFn: async (id: number) => {
      await api.delete(`/coupons/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin/coupons'] });
      message.success('Coupon code deleted');
    }
  });

  const handleOpenEdit = (coupon: any) => {
    setEditingCoupon(coupon);
    // Convert ISO string back to date format for input compatibility
    const formattedCoupon = {
      ...coupon,
      expiry_date: coupon.expiry_date.split('T')[0]
    };
    form.setFieldsValue(formattedCoupon);
    setModalOpen(true);
  };

  const handleSaveCoupon = (values: any) => {
    saveCouponMutation.mutate(values);
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
              <Button type="text" onClick={() => navigate('/admin')} className="font-semibold text-slate-600">Dashboard</Button>
              <Button type="text" onClick={() => navigate('/admin/pricing')} className="font-semibold text-slate-600">Rates Config</Button>
              <Button type="link" onClick={() => navigate('/admin/coupons')} className="font-bold p-0">Discount Coupons</Button>
            </nav>
          </div>

          <Button type="default" icon={<ArrowLeft size={16} />} onClick={() => navigate('/admin')}>
            Back to Dashboard
          </Button>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 mt-8">
        <Card
          className="glass-panel border-none shadow-md"
          title={<span className="font-bold text-sm">Active Discount Coupons</span>}
          extra={
            <Button
              type="primary"
              icon={<Plus size={16} />}
              onClick={() => {
                setEditingCoupon(null);
                form.resetFields();
                setModalOpen(true);
              }}
              className="gradient-primary-bg border-none"
            >
              Create Coupon
            </Button>
          }
        >
          <Table
            dataSource={coupons}
            rowKey="id"
            loading={couponsLoading}
            columns={[
              {
                title: 'Coupon Code',
                dataIndex: 'code',
                key: 'code',
                render: (code) => <strong className="text-blue-600 font-bold select-all">{code}</strong>
              },
              {
                title: 'Discount Type',
                dataIndex: 'discount_type',
                key: 'discount_type',
                render: (type) => <span className="capitalize">{type}</span>
              },
              {
                title: 'Discount Value',
                dataIndex: 'discount_value',
                key: 'discount_value',
                render: (val, record: any) => (
                  <span className="font-bold">
                    {record.discount_type === 'flat' ? `₹${val}` : `${val}%`}
                  </span>
                )
              },
              {
                title: 'Min Order Value',
                dataIndex: 'min_order_value',
                key: 'min_order_value',
                render: (val) => <span>₹{val}</span>
              },
              {
                title: 'Expiry Date',
                dataIndex: 'expiry_date',
                key: 'expiry_date',
                render: (d) => <span>{new Date(d).toLocaleDateString('en-IN')}</span>
              },
              {
                title: 'Status',
                dataIndex: 'status',
                key: 'status',
                render: (status) => (
                  <Tag color={status === 'active' ? 'green' : 'red'} className="font-semibold text-xs capitalize">
                    {status}
                  </Tag>
                )
              },
              {
                title: 'Actions',
                key: 'actions',
                render: (_, record: any) => (
                  <Space>
                    <Button type="link" onClick={() => handleOpenEdit(record)}>Edit</Button>
                    <Popconfirm
                      title="Delete this coupon code?"
                      onConfirm={() => deleteCouponMutation.mutate(record.id)}
                      okText="Yes"
                      cancelText="No"
                    >
                      <Button type="text" danger icon={<Trash2 size={16} />} className="flex items-center justify-center"></Button>
                    </Popconfirm>
                  </Space>
                )
              }
            ]}
          />
        </Card>
      </div>

      {/* Coupon creation/edit modal */}
      <Modal
        title={editingCoupon ? 'Update Coupon Code' : 'Create Coupon Code'}
        open={modalOpen}
        onCancel={() => {
          setModalOpen(false);
          setEditingCoupon(null);
          form.resetFields();
        }}
        footer={null}
      >
        <Form form={form} layout="vertical" onFinish={handleSaveCoupon} requiredMark={false}>
          <Form.Item label="Coupon Code" name="code" rules={[{ required: true, message: 'Please input coupon code!' }]}>
            <Input placeholder="e.g. MONSOON30" className="h-10 font-bold uppercase" />
          </Form.Item>

          <div className="grid grid-cols-2 gap-4">
            <Form.Item label="Discount Type" name="discount_type" rules={[{ required: true }]}>
              <Select placeholder="Select Type">
                <Select.Option value="flat">Flat Value (INR)</Select.Option>
                <Select.Option value="percentage">Percentage (%)</Select.Option>
              </Select>
            </Form.Item>

            <Form.Item label="Discount Value" name="discount_value" rules={[{ required: true }]}>
              <InputNumber min={0} placeholder="e.g. 50" className="w-full h-10 flex items-center" />
            </Form.Item>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <Form.Item label="Minimum Order Value" name="min_order_value" rules={[{ required: true }]}>
              <InputNumber min={0} placeholder="e.g. 200" className="w-full h-10 flex items-center" />
            </Form.Item>

            <Form.Item label="Expiry Date" name="expiry_date" rules={[{ required: true }]}>
              <Input type="date" className="h-10" />
            </Form.Item>
          </div>

          <Form.Item label="Status" name="status" rules={[{ required: true }]}>
            <Select placeholder="Select Status">
              <Select.Option value="active">Active</Select.Option>
              <Select.Option value="inactive">Inactive</Select.Option>
            </Select>
          </Form.Item>

          <Form.Item className="mb-0 text-right">
            <Space>
              <Button onClick={() => setModalOpen(false)}>Cancel</Button>
              <Button type="primary" htmlType="submit" className="gradient-primary-bg border-none" loading={saveCouponMutation.isPending}>
                {editingCoupon ? 'Update Coupon' : 'Create Coupon'}
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
