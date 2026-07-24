'use client';

import React, { useState } from 'react';
import { 
  Shield, 
  BarChart3, 
  Users, 
  Building2, 
  AlertTriangle, 
  CreditCard, 
  Settings, 
  CheckCircle2, 
  XCircle, 
  Search, 
  Filter, 
  Activity, 
  Database, 
  Server, 
  Lock, 
  FileText, 
  DollarSign, 
  Globe, 
  TrendingUp, 
  BadgeCheck, 
  Eye, 
  MoreVertical,
  Layers,
  Sparkles,
  Zap,
  Check,
  Ban
} from 'lucide-react';

// =============================================================================
// TYPES & DATA SCHEMAS (Based on Kaza Conceptual Architecture)
// =============================================================================
type AdminModule = 'DASHBOARD' | 'USERS' | 'LISTINGS' | 'CASES' | 'FINANCE' | 'SYSTEM' | 'COMPLIANCE';

interface AdminUser {
  id: string;
  name: string;
  email: string;
  role: 'ADMIN' | 'MODERATOR' | 'AGENT' | 'ORGANIZATION' | 'USER';
  status: 'ACTIVE' | 'PENDING' | 'SUSPENDED';
  trustScore: number;
  listingsCount: number;
  registeredAt: string;
}

interface AdminListing {
  id: string;
  title: string;
  type: 'Casa' | 'Departamento' | 'Terreno' | 'Oficina';
  price: string;
  location: string;
  mediaStatus: 'VERIFIED_REAL' | 'RENDER_FLAGGED' | 'PENDING_REVIEW';
  status: 'PUBLISHED' | 'UNDER_REVIEW' | 'BANNED' | 'DRAFT';
  publisher: string;
  createdAt: string;
}

interface AdminCase {
  id: string;
  type: 'USER_VERIFICATION' | 'MEDIA_VERACITY' | 'DUPLICATE_LISTING' | 'FAIR_HOUSING_ALERT';
  priority: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
  status: 'NEW' | 'IN_REVIEW' | 'RESOLVED' | 'DISMISSED';
  title: string;
  description: string;
  createdAt: string;
}

export default function AdminDashboardSuite() {
  const [activeModule, setActiveModule] = useState<AdminModule>('DASHBOARD');
  const [searchQuery, setSearchQuery] = useState('');
  const [filterRole, setFilterRole] = useState<string>('ALL');
  const [filterCaseStatus, setFilterCaseStatus] = useState<string>('ALL');

  // ---------------------------------------------------------------------------
  // DEMO DATA - USERS & ORGANIZATIONS
  // ---------------------------------------------------------------------------
  const [users, setUsers] = useState<AdminUser[]>([
    { id: 'usr-1', name: 'Inmobiliaria Kaza Pro', email: 'contacto@kazapro.bo', role: 'ORGANIZATION', status: 'ACTIVE', trustScore: 98, listingsCount: 42, registeredAt: '12 Ene 2026' },
    { id: 'usr-2', name: 'Carlos Mendoza', email: 'cmendoza@agentes.bo', role: 'AGENT', status: 'ACTIVE', trustScore: 92, listingsCount: 15, registeredAt: '15 Feb 2026' },
    { id: 'usr-3', name: 'Constructora El Bosque', email: 'ventas@elbosque.bo', role: 'ORGANIZATION', status: 'PENDING', trustScore: 75, listingsCount: 8, registeredAt: '01 Mar 2026' },
    { id: 'usr-4', name: 'Lucía Gutiérrez', email: 'lucia.g@gmail.com', role: 'USER', status: 'SUSPENDED', trustScore: 40, listingsCount: 1, registeredAt: '10 Abr 2026' },
  ]);

  // ---------------------------------------------------------------------------
  // DEMO DATA - LISTINGS
  // ---------------------------------------------------------------------------
  const [listings, setListings] = useState<AdminListing[]>([
    { id: 'prop-101', title: 'Casa Moderna en Equipetrol Sirari', type: 'Casa', price: '$ 340,000', location: 'Equipetrol, Santa Cruz', mediaStatus: 'VERIFIED_REAL', status: 'PUBLISHED', publisher: 'Carlos Mendoza', createdAt: 'Hace 2 horas' },
    { id: 'prop-102', title: 'Penthouse de Lujo - Condominio La Riviera', type: 'Departamento', price: '$ 128,000', location: 'Centro, Santa Cruz', mediaStatus: 'RENDER_FLAGGED', status: 'UNDER_REVIEW', publisher: 'Inmobiliaria Kaza Pro', createdAt: 'Hace 5 horas' },
    { id: 'prop-103', title: 'Terreno Residencial Urubó - Lote 500m²', type: 'Terreno', price: '$ 85,000', location: 'Urubó Village', mediaStatus: 'VERIFIED_REAL', status: 'PUBLISHED', publisher: 'Constructora El Bosque', createdAt: 'Ayer' },
    { id: 'prop-104', title: 'Oficina Corporativa Torre Empresarial', type: 'Oficina', price: '$ 950 / mes', location: 'Sirari', mediaStatus: 'PENDING_REVIEW', status: 'DRAFT', publisher: 'Lucía Gutiérrez', createdAt: 'Hace 3 días' },
  ]);

  // ---------------------------------------------------------------------------
  // DEMO DATA - CASES & MODERATION
  // ---------------------------------------------------------------------------
  const [cases, setCases] = useState<AdminCase[]>([
    { id: 'case-101', type: 'USER_VERIFICATION', priority: 'HIGH', status: 'NEW', title: 'Verificación Trust Badge: Constructora El Bosque', description: 'Solicitud de insignia certificada con Registro de Comercio FUNDEMPRESA/SEPREC.', createdAt: 'Hace 20 min' },
    { id: 'case-102', type: 'MEDIA_VERACITY', priority: 'MEDIUM', status: 'IN_REVIEW', title: 'Reporte de Veracidad: Foto Render sin etiqueta en Prop-102', description: 'Usuario reporta imagen 3D computarizada etiquetada como foto real en Equipetrol.', createdAt: 'Hace 3 horas' },
    { id: 'case-103', type: 'DUPLICATE_LISTING', priority: 'CRITICAL', status: 'NEW', title: 'Alerta de Duplicado Canónico: Coordenada Urubó', description: 'Detección automática PostGIS: 2 listings sobre las mismas coordenadas con diferencia de precio > $ 15,000.', createdAt: 'Ayer' },
  ]);

  // Handlers
  const handleUserStatusToggle = (id: string, newStatus: 'ACTIVE' | 'SUSPENDED') => {
    setUsers(prev => prev.map(u => u.id === id ? { ...u, status: newStatus } : u));
  };

  const handleListingStatusToggle = (id: string, newStatus: 'PUBLISHED' | 'BANNED') => {
    setListings(prev => prev.map(l => l.id === id ? { ...l, status: newStatus } : l));
  };

  const handleCaseResolve = (id: string) => {
    setCases(prev => prev.map(c => c.id === id ? { ...c, status: 'RESOLVED' } : c));
  };

  return (
    <div style={{ display: 'flex', minHeight: '100vh', backgroundColor: '#0B0F17', color: '#F9FAFB', fontFamily: 'Inter, system-ui, sans-serif' }}>
      
      {/* ===================================================================== */}
      {/* SIDEBAR NAVIGATION (All 6 Modules from Architecture Map) */}
      {/* ===================================================================== */}
      <aside style={{ width: '260px', backgroundColor: '#111723', borderRight: '1px solid rgba(255,255,255,0.08)', padding: '20px 16px', display: 'flex', flexDirection: 'column', gap: '24px' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '10px', backgroundColor: '#E05A47', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Shield size={20} color="#FFF" />
            </div>
            <div>
              <div style={{ fontWeight: '900', fontSize: '18px', letterSpacing: '-0.5px', color: '#FFF' }}>kaza <span style={{ color: '#E05A47', fontSize: '12px', fontWeight: 'bold' }}>ADMIN</span></div>
              <div style={{ fontSize: '10px', color: '#9CA3AF' }}>Gobierno & Backoffice Suite</div>
            </div>
          </div>
        </div>

        <nav style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
          <button
            onClick={() => setActiveModule('DASHBOARD')}
            style={{
              display: 'flex', alignItems: 'center', gap: '12px', padding: '10px 14px', borderRadius: '10px', border: 'none',
              backgroundColor: activeModule === 'DASHBOARD' ? 'rgba(224,90,71,0.15)' : 'transparent',
              color: activeModule === 'DASHBOARD' ? '#E05A47' : '#9CA3AF',
              fontWeight: activeModule === 'DASHBOARD' ? '700' : '500', fontSize: '13px', cursor: 'pointer', textAlign: 'left'
            }}
          >
            <BarChart3 size={18} /> 1. Admin Dashboard
          </button>

          <button
            onClick={() => setActiveModule('USERS')}
            style={{
              display: 'flex', alignItems: 'center', gap: '12px', padding: '10px 14px', borderRadius: '10px', border: 'none',
              backgroundColor: activeModule === 'USERS' ? 'rgba(224,90,71,0.15)' : 'transparent',
              color: activeModule === 'USERS' ? '#E05A47' : '#9CA3AF',
              fontWeight: activeModule === 'USERS' ? '700' : '500', fontSize: '13px', cursor: 'pointer', textAlign: 'left'
            }}
          >
            <Users size={18} /> 2. Users & Org Admin
          </button>

          <button
            onClick={() => setActiveModule('LISTINGS')}
            style={{
              display: 'flex', alignItems: 'center', gap: '12px', padding: '10px 14px', borderRadius: '10px', border: 'none',
              backgroundColor: activeModule === 'LISTINGS' ? 'rgba(224,90,71,0.15)' : 'transparent',
              color: activeModule === 'LISTINGS' ? '#E05A47' : '#9CA3AF',
              fontWeight: activeModule === 'LISTINGS' ? '700' : '500', fontSize: '13px', cursor: 'pointer', textAlign: 'left'
            }}
          >
            <Building2 size={18} /> 3. Content & Listings
          </button>

          <button
            onClick={() => setActiveModule('CASES')}
            style={{
              display: 'flex', alignItems: 'center', gap: '12px', padding: '10px 14px', borderRadius: '10px', border: 'none',
              backgroundColor: activeModule === 'CASES' ? 'rgba(224,90,71,0.15)' : 'transparent',
              color: activeModule === 'CASES' ? '#E05A47' : '#9CA3AF',
              fontWeight: activeModule === 'CASES' ? '700' : '500', fontSize: '13px', cursor: 'pointer', textAlign: 'left'
            }}
          >
            <AlertTriangle size={18} /> 4. Admin Cases & Audit
          </button>

          <button
            onClick={() => setActiveModule('FINANCE')}
            style={{
              display: 'flex', alignItems: 'center', gap: '12px', padding: '10px 14px', borderRadius: '10px', border: 'none',
              backgroundColor: activeModule === 'FINANCE' ? 'rgba(224,90,71,0.15)' : 'transparent',
              color: activeModule === 'FINANCE' ? '#E05A47' : '#9CA3AF',
              fontWeight: activeModule === 'FINANCE' ? '700' : '500', fontSize: '13px', cursor: 'pointer', textAlign: 'left'
            }}
          >
            <CreditCard size={18} /> 5. Finance & Billing
          </button>

          <button
            onClick={() => setActiveModule('SYSTEM')}
            style={{
              display: 'flex', alignItems: 'center', gap: '12px', padding: '10px 14px', borderRadius: '10px', border: 'none',
              backgroundColor: activeModule === 'SYSTEM' ? 'rgba(224,90,71,0.15)' : 'transparent',
              color: activeModule === 'SYSTEM' ? '#E05A47' : '#9CA3AF',
              fontWeight: activeModule === 'SYSTEM' ? '700' : '500', fontSize: '13px', cursor: 'pointer', textAlign: 'left'
            }}
          >
            <Settings size={18} /> 6. System & Market Config
          </button>

          <button
            onClick={() => setActiveModule('COMPLIANCE')}
            style={{
              display: 'flex', alignItems: 'center', gap: '12px', padding: '10px 14px', borderRadius: '10px', border: 'none',
              backgroundColor: activeModule === 'COMPLIANCE' ? 'rgba(16,185,129,0.15)' : 'transparent',
              color: activeModule === 'COMPLIANCE' ? '#10B981' : '#9CA3AF',
              fontWeight: activeModule === 'COMPLIANCE' ? '700' : '500', fontSize: '13px', cursor: 'pointer', textAlign: 'left', marginTop: '12px'
            }}
          >
            <Globe size={18} /> Market Compliance Gate
          </button>
        </nav>

        {/* Footer System Status Badge */}
        <div style={{ marginTop: 'auto', backgroundColor: '#161C26', borderRadius: '12px', padding: '12px', border: '1px solid rgba(255,255,255,0.06)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '11px', color: '#10B981', fontWeight: 'bold' }}>
            <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#10B981', display: 'inline-block' }}></span>
            SYSTEM STATUS: OPERATIONAL
          </div>
          <div style={{ fontSize: '10px', color: '#6B7280', marginTop: '4px' }}>Supabase DB Latency: 14ms</div>
        </div>
      </aside>

      {/* ===================================================================== */}
      {/* MAIN CONTENT AREA */}
      {/* ===================================================================== */}
      <main style={{ flex: 1, padding: '32px', overflowY: 'auto' }}>
        
        {/* TOP HEADER & QUICK STATS BAR */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '28px', flexWrap: 'wrap', gap: '16px' }}>
          <div>
            <h1 style={{ margin: 0, fontSize: '24px', fontWeight: '800', color: '#FFF' }}>
              {activeModule === 'DASHBOARD' && '📊 Admin Dashboard & Salud del Sistema'}
              {activeModule === 'USERS' && '👥 Gestión de Usuarios, Agentes & Inmobiliarias'}
              {activeModule === 'LISTINGS' && '🏠 Moderación de Contenido & Calidad de Publicaciones'}
              {activeModule === 'CASES' && '🛡️ Triaje de Casos (AdminCase System) & Auditoría'}
              {activeModule === 'FINANCE' && '💳 Finanzas, Suscripciones Plus/Pro & Facturación'}
              {activeModule === 'SYSTEM' && '⚙️ Configuración del Sistema, Feature Flags & Market Config'}
              {activeModule === 'COMPLIANCE' && '🌐 Market Launch Compliance Gate (Bolivia DS 4732 / Ley 453)'}
            </h1>
            <p style={{ margin: '4px 0 0 0', fontSize: '13px', color: '#9CA3AF' }}>
              Módulo de Administración según el Modelo Conceptual de Dominio de Kaza
            </p>
          </div>

          {/* Quick Search */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ position: 'relative' }}>
              <Search size={16} color="#9CA3AF" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
              <input
                type="text"
                placeholder="Buscar por ID, usuario, propiedad..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{
                  backgroundColor: '#161C26', border: '1px solid rgba(255,255,255,0.12)', borderRadius: '20px',
                  padding: '8px 16px 8px 36px', color: '#FFF', fontSize: '13px', width: '260px', outline: 'none'
                }}
              />
            </div>
          </div>
        </div>

        {/* =================================================================== */}
        {/* MODULE 1: ADMIN DASHBOARD */}
        {/* =================================================================== */}
        {activeModule === 'DASHBOARD' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
            {/* KPI Cards Grid */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px' }}>
              <div style={{ backgroundColor: '#161C26', padding: '20px', borderRadius: '16px', border: '1px solid rgba(255,255,255,0.08)' }}>
                <div style={{ fontSize: '12px', color: '#9CA3AF', fontWeight: 'bold' }}>PUBLICACIONES ACTIVAS</div>
                <div style={{ fontSize: '32px', fontWeight: '900', color: '#E05A47', marginTop: '6px' }}>1,420</div>
                <div style={{ fontSize: '11px', color: '#10B981', marginTop: '4px' }}>↑ +14% respecto al mes anterior</div>
              </div>

              <div style={{ backgroundColor: '#161C26', padding: '20px', borderRadius: '16px', border: '1px solid rgba(255,255,255,0.08)' }}>
                <div style={{ fontSize: '12px', color: '#9CA3AF', fontWeight: 'bold' }}>USUARIOS Y AGENTES</div>
                <div style={{ fontSize: '32px', fontWeight: '900', color: '#F6BD7B', marginTop: '6px' }}>8,940</div>
                <div style={{ fontSize: '11px', color: '#10B981', marginTop: '4px' }}>98.2% Trust Score Promedio</div>
              </div>

              <div style={{ backgroundColor: '#161C26', padding: '20px', borderRadius: '16px', border: '1px solid rgba(255,255,255,0.08)' }}>
                <div style={{ fontSize: '12px', color: '#9CA3AF', fontWeight: 'bold' }}>INGRESOS MENSUALES (MRR)</div>
                <div style={{ fontSize: '32px', fontWeight: '900', color: '#10B981', marginTop: '6px' }}>$ 18,450</div>
                <div style={{ fontSize: '11px', color: '#9CA3AF', marginTop: '4px' }}>Suscripciones Pro + Destacados</div>
              </div>

              <div style={{ backgroundColor: '#161C26', padding: '20px', borderRadius: '16px', border: '1px solid rgba(255,255,255,0.08)' }}>
                <div style={{ fontSize: '12px', color: '#9CA3AF', fontWeight: 'bold' }}>CASOS PENDIENTES</div>
                <div style={{ fontSize: '32px', fontWeight: '900', color: '#EF4444', marginTop: '6px' }}>03</div>
                <div style={{ fontSize: '11px', color: '#EF4444', marginTop: '4px' }}>01 Alerta Crítica en Urubó</div>
              </div>
            </div>

            {/* System Health Monitor */}
            <div style={{ backgroundColor: '#161C26', borderRadius: '16px', padding: '24px', border: '1px solid rgba(255,255,255,0.08)' }}>
              <h3 style={{ margin: '0 0 16px 0', fontSize: '16px', color: '#FFF', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Server size={18} color="#10B981" /> Monitor de Salud del Sistema (Infraestructura Kaza)
              </h3>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px' }}>
                <div style={{ backgroundColor: '#0B0F17', padding: '14px', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.06)' }}>
                  <div style={{ fontSize: '11px', color: '#9CA3AF' }}>Base de Datos PostgreSQL (PostGIS)</div>
                  <div style={{ fontSize: '16px', fontWeight: 'bold', color: '#10B981', marginTop: '4px' }}>ONLINE (14ms)</div>
                </div>
                <div style={{ backgroundColor: '#0B0F17', padding: '14px', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.06)' }}>
                  <div style={{ fontSize: '11px', color: '#9CA3AF' }}>Supabase Storage CDN</div>
                  <div style={{ fontSize: '16px', fontWeight: 'bold', color: '#10B981', marginTop: '4px' }}>1.2 TB / 5.0 TB</div>
                </div>
                <div style={{ backgroundColor: '#0B0F17', padding: '14px', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.06)' }}>
                  <div style={{ fontSize: '11px', color: '#9CA3AF' }}>Geo-Search Index ST_Contains</div>
                  <div style={{ fontSize: '16px', fontWeight: 'bold', color: '#10B981', marginTop: '4px' }}>22ms Avg Query</div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* =================================================================== */}
        {/* MODULE 2: USER & ORGANIZATION ADMIN */}
        {/* =================================================================== */}
        {activeModule === 'USERS' && (
          <div style={{ backgroundColor: '#161C26', borderRadius: '16px', padding: '24px', border: '1px solid rgba(255,255,255,0.08)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h3 style={{ margin: 0, fontSize: '16px' }}>Gestión de Usuarios, Agentes & Inmobiliarias</h3>
              <div style={{ display: 'flex', gap: '8px' }}>
                {['ALL', 'ORGANIZATION', 'AGENT', 'USER'].map(r => (
                  <button
                    key={r}
                    onClick={() => setFilterRole(r)}
                    style={{
                      backgroundColor: filterRole === r ? '#E05A47' : 'transparent',
                      color: filterRole === r ? '#FFF' : '#9CA3AF',
                      border: '1px solid rgba(255,255,255,0.1)', padding: '6px 14px', borderRadius: '20px', fontSize: '12px', cursor: 'pointer'
                    }}
                  >
                    {r}
                  </button>
                ))}
              </div>
            </div>

            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
              <thead>
                <tr style={{ color: '#9CA3AF', borderBottom: '1px solid rgba(255,255,255,0.08)', textAlign: 'left' }}>
                  <th style={{ padding: '12px' }}>Usuario / Entidad</th>
                  <th style={{ padding: '12px' }}>Rol</th>
                  <th style={{ padding: '12px' }}>Trust Score</th>
                  <th style={{ padding: '12px' }}>Listings</th>
                  <th style={{ padding: '12px' }}>Estado</th>
                  <th style={{ padding: '12px' }}>Acciones</th>
                </tr>
              </thead>
              <tbody>
                {users.filter(u => filterRole === 'ALL' || u.role === filterRole).map(u => (
                  <tr key={u.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                    <td style={{ padding: '12px' }}>
                      <div style={{ fontWeight: 'bold', color: '#FFF' }}>{u.name}</div>
                      <div style={{ fontSize: '11px', color: '#9CA3AF' }}>{u.email}</div>
                    </td>
                    <td style={{ padding: '12px' }}>
                      <span style={{ fontSize: '11px', fontWeight: 'bold', padding: '2px 8px', borderRadius: '4px', backgroundColor: 'rgba(255,255,255,0.06)', color: '#F6BD7B' }}>
                        {u.role}
                      </span>
                    </td>
                    <td style={{ padding: '12px', fontWeight: 'bold', color: '#10B981' }}>{u.trustScore} pts</td>
                    <td style={{ padding: '12px' }}>{u.listingsCount} anuncios</td>
                    <td style={{ padding: '12px' }}>
                      <span style={{
                        fontSize: '11px', fontWeight: 'bold', padding: '4px 8px', borderRadius: '6px',
                        backgroundColor: u.status === 'ACTIVE' ? 'rgba(16,185,129,0.15)' : u.status === 'PENDING' ? 'rgba(245,158,11,0.15)' : 'rgba(239,68,68,0.15)',
                        color: u.status === 'ACTIVE' ? '#10B981' : u.status === 'PENDING' ? '#F59E0B' : '#EF4444'
                      }}>
                        {u.status}
                      </span>
                    </td>
                    <td style={{ padding: '12px' }}>
                      {u.status === 'ACTIVE' ? (
                        <button
                          onClick={() => handleUserStatusToggle(u.id, 'SUSPENDED')}
                          style={{ backgroundColor: 'transparent', border: '1px solid #EF4444', color: '#EF4444', padding: '4px 10px', borderRadius: '6px', cursor: 'pointer', fontSize: '11px' }}
                        >
                          Suspender
                        </button>
                      ) : (
                        <button
                          onClick={() => handleUserStatusToggle(u.id, 'ACTIVE')}
                          style={{ backgroundColor: '#10B981', border: 'none', color: '#FFF', padding: '4px 10px', borderRadius: '6px', cursor: 'pointer', fontSize: '11px', fontWeight: 'bold' }}
                        >
                          Activar / Aprobar
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* =================================================================== */}
        {/* MODULE 3: CONTENT & LISTINGS ADMIN */}
        {/* =================================================================== */}
        {activeModule === 'LISTINGS' && (
          <div style={{ backgroundColor: '#161C26', borderRadius: '16px', padding: '24px', border: '1px solid rgba(255,255,255,0.08)' }}>
            <h3 style={{ margin: '0 0 20px 0', fontSize: '16px' }}>Revisión de Contenido & Veracidad de Inmuebles</h3>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
              <thead>
                <tr style={{ color: '#9CA3AF', borderBottom: '1px solid rgba(255,255,255,0.08)', textAlign: 'left' }}>
                  <th style={{ padding: '12px' }}>Propiedad</th>
                  <th style={{ padding: '12px' }}>Precio & Zona</th>
                  <th style={{ padding: '12px' }}>Veracidad Media</th>
                  <th style={{ padding: '12px' }}>Estado</th>
                  <th style={{ padding: '12px' }}>Acciones</th>
                </tr>
              </thead>
              <tbody>
                {listings.map(l => (
                  <tr key={l.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                    <td style={{ padding: '12px' }}>
                      <div style={{ fontWeight: 'bold', color: '#FFF' }}>{l.title}</div>
                      <div style={{ fontSize: '11px', color: '#9CA3AF' }}>Publicado por: {l.publisher}</div>
                    </td>
                    <td style={{ padding: '12px' }}>
                      <div style={{ fontWeight: 'bold', color: '#F6BD7B' }}>{l.price}</div>
                      <div style={{ fontSize: '11px', color: '#9CA3AF' }}>{l.location}</div>
                    </td>
                    <td style={{ padding: '12px' }}>
                      <span style={{
                        fontSize: '11px', fontWeight: 'bold', padding: '4px 8px', borderRadius: '6px',
                        backgroundColor: l.mediaStatus === 'VERIFIED_REAL' ? 'rgba(16,185,129,0.15)' : 'rgba(239,68,68,0.15)',
                        color: l.mediaStatus === 'VERIFIED_REAL' ? '#10B981' : '#EF4444'
                      }}>
                        {l.mediaStatus === 'VERIFIED_REAL' ? '✓ FOTO REAL VERIFICADA' : '⚠️ RENDER DETECTADO'}
                      </span>
                    </td>
                    <td style={{ padding: '12px' }}>
                      <span style={{ fontSize: '11px', fontWeight: 'bold', padding: '4px 8px', borderRadius: '6px', backgroundColor: 'rgba(255,255,255,0.06)', color: '#FFF' }}>
                        {l.status}
                      </span>
                    </td>
                    <td style={{ padding: '12px' }}>
                      {l.status === 'PUBLISHED' ? (
                        <button
                          onClick={() => handleListingStatusToggle(l.id, 'BANNED')}
                          style={{ backgroundColor: 'transparent', border: '1px solid #EF4444', color: '#EF4444', padding: '4px 10px', borderRadius: '6px', cursor: 'pointer', fontSize: '11px' }}
                        >
                          Pausar / Banear
                        </button>
                      ) : (
                        <button
                          onClick={() => handleListingStatusToggle(l.id, 'PUBLISHED')}
                          style={{ backgroundColor: '#10B981', border: 'none', color: '#FFF', padding: '4px 10px', borderRadius: '6px', cursor: 'pointer', fontSize: '11px', fontWeight: 'bold' }}
                        >
                          Aprobar Publicación
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* =================================================================== */}
        {/* MODULE 4: ADMIN CASES & MODERATION */}
        {/* =================================================================== */}
        {activeModule === 'CASES' && (
          <div style={{ backgroundColor: '#161C26', borderRadius: '16px', padding: '24px', border: '1px solid rgba(255,255,255,0.08)' }}>
            <h3 style={{ margin: '0 0 20px 0', fontSize: '16px' }}>🛡️ Triaje de Casos (AdminCase System) & Auditoría</h3>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
              <thead>
                <tr style={{ color: '#9CA3AF', borderBottom: '1px solid rgba(255,255,255,0.08)', textAlign: 'left' }}>
                  <th style={{ padding: '12px' }}>ID & Prioridad</th>
                  <th style={{ padding: '12px' }}>Tipo de Caso</th>
                  <th style={{ padding: '12px' }}>Detalles de la Incidencia</th>
                  <th style={{ padding: '12px' }}>Estado</th>
                  <th style={{ padding: '12px' }}>Acción de Resolución</th>
                </tr>
              </thead>
              <tbody>
                {cases.map(c => (
                  <tr key={c.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                    <td style={{ padding: '12px' }}>
                      <div style={{ fontWeight: 'bold' }}>{c.id}</div>
                      <span style={{ fontSize: '10px', fontWeight: 'bold', color: c.priority === 'CRITICAL' ? '#EF4444' : '#F59E0B' }}>
                        {c.priority}
                      </span>
                    </td>
                    <td style={{ padding: '12px', fontWeight: 'bold', color: '#E05A47' }}>{c.type}</td>
                    <td style={{ padding: '12px' }}>
                      <div style={{ fontWeight: 'bold', color: '#FFF' }}>{c.title}</div>
                      <div style={{ fontSize: '11px', color: '#9CA3AF', marginTop: '2px' }}>{c.description}</div>
                    </td>
                    <td style={{ padding: '12px' }}>
                      <span style={{
                        fontSize: '11px', fontWeight: 'bold', padding: '4px 8px', borderRadius: '6px',
                        backgroundColor: c.status === 'RESOLVED' ? 'rgba(16,185,129,0.15)' : 'rgba(245,158,11,0.15)',
                        color: c.status === 'RESOLVED' ? '#10B981' : '#F59E0B'
                      }}>
                        {c.status}
                      </span>
                    </td>
                    <td style={{ padding: '12px' }}>
                      {c.status !== 'RESOLVED' && (
                        <button
                          onClick={() => handleCaseResolve(c.id)}
                          style={{ backgroundColor: '#10B981', border: 'none', color: '#FFF', padding: '6px 12px', borderRadius: '6px', cursor: 'pointer', fontSize: '11px', fontWeight: 'bold' }}
                        >
                          Resolver Caso
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* =================================================================== */}
        {/* MODULE 5: FINANCE & BILLING ADMIN */}
        {/* =================================================================== */}
        {activeModule === 'FINANCE' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            <div style={{ backgroundColor: '#161C26', borderRadius: '16px', padding: '24px', border: '1px solid rgba(255,255,255,0.08)' }}>
              <h3 style={{ margin: '0 0 16px 0', fontSize: '16px' }}>💳 Planes de Suscripción & Transacciones</h3>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '16px' }}>
                <div style={{ backgroundColor: '#0B0F17', padding: '16px', borderRadius: '12px' }}>
                  <div style={{ fontSize: '12px', color: '#9CA3AF' }}>Suscripción Inmobiliarias PRO</div>
                  <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#FFF', marginTop: '4px' }}>$ 299 / mes</div>
                  <div style={{ fontSize: '11px', color: '#10B981', marginTop: '4px' }}>48 Inmobiliarias registradas</div>
                </div>
                <div style={{ backgroundColor: '#0B0F17', padding: '16px', borderRadius: '12px' }}>
                  <div style={{ fontSize: '12px', color: '#9CA3AF' }}>Destacados Plus (Pago por Listing)</div>
                  <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#F6BD7B', marginTop: '4px' }}>$ 19 / anuncio</div>
                  <div style={{ fontSize: '11px', color: '#10B981', marginTop: '4px' }}>210 anuncios promocionados</div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* =================================================================== */}
        {/* MODULE 6: SYSTEM & MARKET CONFIG */}
        {/* =================================================================== */}
        {activeModule === 'SYSTEM' && (
          <div style={{ backgroundColor: '#161C26', borderRadius: '16px', padding: '24px', border: '1px solid rgba(255,255,255,0.08)' }}>
            <h3 style={{ margin: '0 0 16px 0', fontSize: '16px' }}>⚙️ Configuración del Sistema & Feature Flags</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px', backgroundColor: '#0B0F17', borderRadius: '10px' }}>
                <div>
                  <div style={{ fontWeight: 'bold' }}>Visor 3D Interactivo 360°</div>
                  <div style={{ fontSize: '12px', color: '#9CA3AF' }}>Habilitar renderizado orbital espacial en detalle de propiedad</div>
                </div>
                <span style={{ padding: '4px 10px', borderRadius: '12px', backgroundColor: 'rgba(16,185,129,0.15)', color: '#10B981', fontWeight: 'bold', fontSize: '12px' }}>ACTIVADO</span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px', backgroundColor: '#0B0F17', borderRadius: '10px' }}>
                <div>
                  <div style={{ fontWeight: 'bold' }}>Búsqueda Poligonal PostGIS (Dibujo Libre)</div>
                  <div style={{ fontSize: '12px', color: '#9CA3AF' }}>Permitir delimitación manual de zona en el mapa</div>
                </div>
                <span style={{ padding: '4px 10px', borderRadius: '12px', backgroundColor: 'rgba(16,185,129,0.15)', color: '#10B981', fontWeight: 'bold', fontSize: '12px' }}>ACTIVADO</span>
              </div>
            </div>
          </div>
        )}

        {/* =================================================================== */}
        {/* MODULE 7: MARKET LAUNCH COMPLIANCE GATE */}
        {/* =================================================================== */}
        {activeModule === 'COMPLIANCE' && (
          <div style={{ backgroundColor: '#161C26', borderRadius: '16px', padding: '24px', border: '1px solid rgba(255,255,255,0.08)' }}>
            <h3 style={{ margin: '0 0 12px 0', fontSize: '18px', color: '#10B981' }}>🌐 Market Launch Compliance Gate — Bolivia (BOL)</h3>
            <p style={{ color: '#9CA3AF', fontSize: '13px', marginBottom: '20px' }}>
              Verificación estricta de cumplimiento normativo de acuerdo a la Ley 453 y el Decreto Supremo 4732 de Contratos de Preventa:
            </p>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '12px' }}>
              <div style={{ backgroundColor: '#0B0F17', padding: '16px', borderRadius: '12px', borderLeft: '4px solid #10B981' }}>
                <div style={{ fontSize: '11px', color: '#10B981', fontWeight: 'bold' }}>1. RESEARCH</div>
                <div style={{ fontSize: '14px', fontWeight: 'bold', marginTop: '4px', color: '#FFF' }}>Ley 453 & DS 4732</div>
                <div style={{ fontSize: '11px', color: '#10B981', marginTop: '6px' }}>✓ APROBADO</div>
              </div>

              <div style={{ backgroundColor: '#0B0F17', padding: '16px', borderRadius: '12px', borderLeft: '4px solid #10B981' }}>
                <div style={{ fontSize: '11px', color: '#10B981', fontWeight: 'bold' }}>2. LEGAL_REVIEW</div>
                <div style={{ fontSize: '14px', fontWeight: 'bold', marginTop: '4px', color: '#FFF' }}>VDDUC Preventas</div>
                <div style={{ fontSize: '11px', color: '#10B981', marginTop: '6px' }}>✓ CERTIFICADO</div>
              </div>

              <div style={{ backgroundColor: '#0B0F17', padding: '16px', borderRadius: '12px', borderLeft: '4px solid #10B981' }}>
                <div style={{ fontSize: '11px', color: '#10B981', fontWeight: 'bold' }}>3. TECH_READY</div>
                <div style={{ fontSize: '14px', fontWeight: 'bold', marginTop: '4px', color: '#FFF' }}>PostGIS & Next.js</div>
                <div style={{ fontSize: '11px', color: '#10B981', marginTop: '6px' }}>✓ DESPLEGADO</div>
              </div>

              <div style={{ backgroundColor: '#0B0F17', padding: '16px', borderRadius: '12px', borderLeft: '4px solid #F59E0B' }}>
                <div style={{ fontSize: '11px', color: '#F59E0B', fontWeight: 'bold' }}>4. STORE_READY</div>
                <div style={{ fontSize: '14px', fontWeight: 'bold', marginTop: '4px', color: '#FFF' }}>Apple/Google IAP</div>
                <div style={{ fontSize: '11px', color: '#F59E0B', marginTop: '6px' }}>EN PROCESO</div>
              </div>

              <div style={{ backgroundColor: '#0B0F17', padding: '16px', borderRadius: '12px', borderLeft: '4px solid #6B7280' }}>
                <div style={{ fontSize: '11px', color: '#6B7280', fontWeight: 'bold' }}>5. ENABLED</div>
                <div style={{ fontSize: '14px', fontWeight: 'bold', marginTop: '4px', color: '#FFF' }}>Lanzamiento Comercial</div>
                <div style={{ fontSize: '11px', color: '#6B7280', marginTop: '6px' }}>PENDIENTE GATE 4</div>
              </div>
            </div>
          </div>
        )}

      </main>
    </div>
  );
}
