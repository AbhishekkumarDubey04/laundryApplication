import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, Input, Button, Form, message, Alert, Space } from 'antd';
import { Phone, Lock, Sparkles, ArrowLeft } from 'lucide-react';
import api from '../services/api.ts';
import useAuthStore from '../store/useAuthStore.ts';

export default function LoginPage() {
  const navigate = useNavigate();
  const setAuth = useAuthStore((state) => state.setAuth);

  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [step, setStep] = useState<'phone' | 'otp'>('phone');
  const [phone, setPhone] = useState('');
  const [debugOtp, setDebugOtp] = useState<string | null>(null);

  // Handles requesting OTP code
  const handleSendOtp = async (values: { phone: string }) => {
    let formattedPhone = values.phone.trim();
    
    // Auto-prefix with +91 if user inputs a 10-digit number
    if (/^\d{10}$/.test(formattedPhone)) {
      formattedPhone = `+91${formattedPhone}`;
    }

    if (!/^\+91\d{10}$/.test(formattedPhone)) {
      message.error('Please input a valid 10-digit phone number (optionally prefixed with +91)');
      return;
    }

    setLoading(true);
    try {
      const res = await api.post('/auth/send-otp', { phone: formattedPhone });
      message.success('OTP sent successfully (Simulated)');
      setPhone(formattedPhone);
      setStep('otp');
      if (res.data.debugOtp) {
        setDebugOtp(res.data.debugOtp);
      }
    } catch (err: any) {
      console.error(err);
      message.error(err.response?.data?.error || 'Failed to send OTP code. Please retry.');
    } finally {
      setLoading(false);
    }
  };

  // Handles verifying OTP and creating/logging in session
  const handleVerifyOtp = async (values: { otp: string }) => {
    setLoading(true);
    try {
      const res = await api.post('/auth/verify-otp', { phone, otp: values.otp });
      message.success('Login successful!');
      
      const { token, user } = res.data;
      setAuth(token, user);

      // Redirect depending on user role
      if (user.role === 'admin') {
        navigate('/admin');
      } else {
        navigate('/dashboard');
      }
    } catch (err: any) {
      console.error(err);
      message.error(err.response?.data?.error || 'OTP verification failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col justify-center items-center px-4" style={{ backgroundColor: 'var(--bg-primary)' }}>
      {/* Floating Back arrow */}
      <div className="absolute top-6 left-6">
        <Button
          type="text"
          icon={<ArrowLeft size={18} />}
          onClick={() => navigate('/')}
          className="flex items-center space-x-2 font-medium"
        >
          Back to Home
        </Button>
      </div>

      <div className="w-full max-w-md animate-fade-in">
        {/* Logo Header */}
        <div className="flex flex-col items-center mb-8 space-y-2">
          <div className="h-12 w-12 rounded-2xl gradient-primary-bg flex items-center justify-center text-white font-extrabold text-2xl shadow-lg">
            L
          </div>
          <h2 className="font-extrabold text-2xl tracking-tight" style={{ fontFamily: 'Outfit' }}>
            Welcome to <span style={{ color: 'var(--primary-color)' }}>LaundryIndia</span>
          </h2>
          <p className="text-sm" style={{ color: 'var(--text-muted)' }}>
            OTP-based secure checkout. No password required.
          </p>
        </div>

        <Card className="glass-panel border-none p-4 sm:p-6 shadow-xl">
          {step === 'phone' ? (
            <Form form={form} layout="vertical" onFinish={handleSendOtp} requiredMark={false}>
              <Form.Item
                label={<span className="font-semibold text-sm">Enter Mobile Number</span>}
                name="phone"
                rules={[{ required: true, message: 'Please input your phone number!' }]}
              >
                <Input
                  prefix={<Phone size={18} className="text-slate-400 mr-2" />}
                  placeholder="e.g. 9999999999"
                  maxLength={13}
                  className="rounded-lg h-11"
                  disabled={loading}
                />
              </Form.Item>

              <Form.Item className="mb-0">
                <Button
                  type="primary"
                  htmlType="submit"
                  block
                  loading={loading}
                  className="gradient-primary-bg h-11 text-sm font-semibold border-none"
                >
                  Send OTP Code
                </Button>
              </Form.Item>

              {/* Developer Testing Note */}
              <div className="mt-6 border-t pt-4 text-xs" style={{ borderColor: 'var(--border-color)', color: 'var(--text-muted)' }}>
                <p className="font-semibold mb-1">Developer test phone numbers:</p>
                <ul className="list-disc pl-4 space-y-1">
                  <li><strong>+919999999999</strong>: Seeded Admin User</li>
                  <li>Any other number: Creates a new customer account</li>
                </ul>
              </div>
            </Form>
          ) : (
            <Form layout="vertical" onFinish={handleVerifyOtp} requiredMark={false}>
              <div className="mb-4 text-center">
                <span className="text-sm block" style={{ color: 'var(--text-muted)' }}>
                  We sent a 6-digit OTP code to:
                </span>
                <span className="font-bold text-sm block">{phone}</span>
                <Button
                  type="link"
                  size="small"
                  className="p-0 h-auto mt-1"
                  onClick={() => {
                    setStep('phone');
                    setDebugOtp(null);
                  }}
                >
                  Change Phone Number
                </Button>
              </div>

              {debugOtp && (
                <Alert
                  message={
                    <div className="text-xs">
                      Simulated OTP code is: <strong className="text-blue-600 text-sm select-all">{debugOtp}</strong>
                      <br />
                      (Or enter standard bypass code <strong className="text-sm select-all">123456</strong>)
                    </div>
                  }
                  type="info"
                  showIcon
                  icon={<Sparkles size={16} />}
                  className="mb-4"
                />
              )}

              <Form.Item
                label={<span className="font-semibold text-sm">Enter OTP Verification Code</span>}
                name="otp"
                rules={[{ required: true, message: 'Please input the 6-digit code!' }]}
              >
                <Input
                  prefix={<Lock size={18} className="text-slate-400 mr-2" />}
                  placeholder="e.g. 123456"
                  maxLength={6}
                  className="rounded-lg h-11 text-center font-bold tracking-widest text-lg"
                  disabled={loading}
                />
              </Form.Item>

              <Form.Item className="mb-0">
                <Button
                  type="primary"
                  htmlType="submit"
                  block
                  loading={loading}
                  className="gradient-primary-bg h-11 text-sm font-semibold border-none"
                >
                  Verify & Log In
                </Button>
              </Form.Item>
            </Form>
          )}
        </Card>
      </div>
    </div>
  );
}
