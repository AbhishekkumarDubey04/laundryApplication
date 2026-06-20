import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Card, Button, Table, Modal, Form, InputNumber, Select, Space, Popconfirm, message, Tag } from 'antd';
import { ArrowLeft, Plus, Trash2, Edit2, LogOut, IndianRupee } from 'lucide-react';
import api from '../services/api.ts';

export default function AdminPricing() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const [modalOpen, setModalOpen] = useState(false);
  const [form] = Form.useForm();

  // Queries
  const { data: pricing = [], isLoading: pricingLoading } = useQuery({
    queryKey: ['admin/raw-pricing'],
    queryFn: async () => {
      const res = await api.get('/services/raw-pricing');
      return res.data;
    }
  });

  const { data: services = [] } = useQuery({
    queryKey: ['services/list-simple'],
    queryFn: async () => {
      const res = await api.get('/services');
      return res.data;
    }
  });

  const { data: items = [] } = useQuery({
    queryKey: ['services/items-simple'],
    queryFn: async () => {
      const res = await api.get('/services/items');
      return res.data;
    }
  });

  // Mutations
  const addPricingMutation = useMutation({
    mutationFn: async (values: any) => {
      const res = await api.post('/services/pricing', values);
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin/raw-pricing'] });
      message.success('Rates configuration updated');
      setModalOpen(false);
      form.resetFields();
    },
    onError: () => {
      message.error('Failed to configure rate.');
    }
  });

  const deletePricingMutation = useMutation({
    mutationFn: async (id: number) => {
      await api.delete(`/services/pricing/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin/raw-pricing'] });
      message.success('Pricing row removed successfully');
    }
  });

  const handleSavePricing = (values: any) => {
    addPricingMutation.mutate(values);
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
              <Button type="link" onClick={() => navigate('/admin/pricing')} className="font-bold p-0">Rates Config</Button>
              <Button type="text" onClick={() => navigate('/admin/coupons')} className="font-semibold text-slate-600">Discount Coupons</Button>
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
          title={<span className="font-bold text-sm">Service Rates Configurator</span>}
          extra={
            <Button
              type="primary"
              icon={<Plus size={16} />}
              onClick={() => setModalOpen(true)}
              className="gradient-primary-bg border-none"
            >
              Add Pricing Rate
            </Button>
          }
        >
          <Table
            dataSource={pricing}
            rowKey="id"
            loading={pricingLoading}
            columns={[
              {
                title: 'Service Category',
                dataIndex: 'service_name',
                key: 'service_name',
                filters: services.map((s: any) => ({ text: s.name, value: s.name })),
                onFilter: (value: any, record: any) => record.service_name === value
              },
              {
                title: 'Garment Item',
                dataIndex: 'item_name',
                key: 'item_name',
                sorter: (a: any, b: any) => a.item_name.localeCompare(b.item_name)
              },
              {
                title: 'Category Tag',
                dataIndex: 'item_category',
                key: 'item_category',
                render: (cat) => <Tag color="blue">{cat}</Tag>
              },
              {
                title: 'Price Rate',
                dataIndex: 'price',
                key: 'price',
                render: (val) => <span className="font-bold text-slate-800">₹{val}</span>,
                sorter: (a: any, b: any) => parseFloat(a.price) - parseFloat(b.price)
              },
              {
                title: 'Action',
                key: 'action',
                render: (_, record: any) => (
                  <Popconfirm
                    title="Delete this pricing configuration?"
                    onConfirm={() => deletePricingMutation.mutate(record.id)}
                    okText="Yes"
                    cancelText="No"
                  >
                    <Button type="text" danger icon={<Trash2 size={16} />} className="flex items-center justify-center"></Button>
                  </Popconfirm>
                )
              }
            ]}
          />
        </Card>
      </div>

      {/* Add pricing rates modal */}
      <Modal
        title="Configure Pricing Rate"
        open={modalOpen}
        onCancel={() => {
          setModalOpen(false);
          form.resetFields();
        }}
        footer={null}
      >
        <Form form={form} layout="vertical" onFinish={handleSavePricing} requiredMark={false}>
          <Form.Item label="Laundry Service" name="service_id" rules={[{ required: true }]}>
            <Select placeholder="Select Service Category">
              {services.map((s: any) => (
                <Select.Option key={s.id} value={s.id}>{s.name}</Select.Option>
              ))}
            </Select>
          </Form.Item>

          <Form.Item label="Clothing Item" name="item_id" rules={[{ required: true }]}>
            <Select placeholder="Select Clothing Item">
              {items.map((i: any) => (
                <Select.Option key={i.id} value={i.id}>{i.name} ({i.category})</Select.Option>
              ))}
            </Select>
          </Form.Item>

          <Form.Item label="Price Rate (INR)" name="price" rules={[{ required: true }]}>
            <InputNumber min={0} placeholder="e.g. 25" className="w-full h-10 flex items-center" prefix={<IndianRupee size={16} className="text-slate-400 mr-2" />} />
          </Form.Item>

          <Form.Item className="mb-0 text-right">
            <Space>
              <Button onClick={() => setModalOpen(false)}>Cancel</Button>
              <Button type="primary" htmlType="submit" className="gradient-primary-bg border-none" loading={addPricingMutation.isPending}>
                Save Config
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
