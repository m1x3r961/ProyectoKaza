'use client';
// Kaza Admin Backoffice Dashboard - Trigger Deploy

import React, { useState } from 'react';

interface AdminCaseItem {
  id: string;
  caseType: string;
  status: string;
  priority: string;
  title: string;
  description: string;
  createdAt: string;
}

export default function AdminDashboardPage() {
  const [selectedTab, setSelectedTab] = useState<'CASES' | 'GATE' | 'AUDIT'>('CASES');
  const [filterStatus, setFilterStatus] = useState<string>('ALL');
  
  const [cases, setCases] = useState<AdminCaseItem[]>([
    {
      id: 'case-101',
      caseType: 'USER_VERIFICATION',
      status: 'NEW',
      priority: 'HIGH',
      title: 'Verificación de Identidad: Inmobiliaria Kaza Pro',
      description: 'Solicitud de insignia Trust Badge con certificado oficial de registro de comercio.',
      createdAt: 'Hace 25 min'
    },
    {
      id: 'case-102',
      caseType: 'MEDIA_VERACITY_REPORT',
      status: 'TRIAGED',
      priority: 'MEDIUM',
      title: 'Reporte de Veracidad: Imagen RENDER etiquetada como REAL_PHOTO',
      description: 'Usuario reporta discrepancia entre la foto real y la imagen principal del inmueble en Equipetrol.',
      createdAt: 'Hace 2 horas'
    },
    {
      id: 'case-103',
      caseType: 'REPORT_LISTING',
      status: 'IN_REVIEW',
      priority: 'CRITICAL',
      title: 'Alerta de Duplicado de Propiedad en Urubó',
      description: 'Detección automática de discrepancia de precio sobre la misma coordenada canónica.',
      createdAt: 'Ayer'
    }
  ]);

  const updateCaseStatus = (id: string, newStatus: string) => {
    setCases(prev => prev.map(c => c.id === id ? { ...c, status: newStatus } : c));
  };

  const filteredCases = filterStatus === 'ALL' ? cases : cases.filter(c => c.status === filterStatus);

  return (
    <div style={{
      minHeight: '100vh',
      backgroundColor: '#0B0F17',
      color: '#F9FAFB',
      fontFamily: 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      padding: '24px'
    }}>
      {/* Header */}
      <header style={{
        borderBottom: '1px solid rgba(255,255,255,0.1)',
        paddingBottom: '16px',
        marginBottom: '24px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        flexWrap: 'wrap',
        gap: '12px'
      }}>
        <div>
          <h1 style={{ margin: 0, fontSize: '24px', color: '#14B8A6', display: 'flex', alignItems: 'center', gap: '8px' }}>
            🛡️ Kaza Backoffice Admin <span style={{ fontSize: '12px', backgroundColor: '#0D9488', color: '#FFF', padding: '2px 8px', borderRadius: '12px' }}>v0.2</span>
          </h1>
          <p style={{ margin: '4px 0 0 0', color: '#9CA3AF', fontSize: '13px' }}>
            Consola de Moderación Desktop-First · Triaje de AdminCase, Verificación de Identidad & Market Launch Gates
          </p>
        </div>
        <div style={{
          backgroundColor: '#161E2E',
          padding: '8px 16px',
          borderRadius: '20px',
          border: '1px solid rgba(255,255,255,0.15)',
          fontSize: '12px',
          color: '#F59E0B',
          fontWeight: 'bold',
          display: 'flex',
          alignItems: 'center',
          gap: '6px'
        }}>
          <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#10B981' }}></span>
          MARKET LAUNCH GATE: BOLIVIA (TECH_READY)
        </div>
      </header>

      {/* Main Metric Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '16px', marginBottom: '24px' }}>
        <div style={{ backgroundColor: '#161E2E', borderRadius: '12px', padding: '16px', border: '1px solid rgba(255,255,255,0.1)' }}>
          <div style={{ color: '#9CA3AF', fontSize: '12px', fontWeight: 'bold' }}>CASOS EN TRIAJE</div>
          <div style={{ fontSize: '28px', fontWeight: 'bold', color: '#F59E0B', marginTop: '4px' }}>03</div>
          <div style={{ color: '#6B7280', fontSize: '11px', marginTop: '4px' }}>01 Crítico · 01 En Revisión</div>
        </div>

        <div style={{ backgroundColor: '#161E2E', borderRadius: '12px', padding: '16px', border: '1px solid rgba(255,255,255,0.1)' }}>
          <div style={{ color: '#9CA3AF', fontSize: '12px', fontWeight: 'bold' }}>VERIFICACIONES TRUST</div>
          <div style={{ fontSize: '28px', fontWeight: 'bold', color: '#2563EB', marginTop: '4px' }}>12</div>
          <div style={{ color: '#6B7280', fontSize: '11px', marginTop: '4px' }}>Inmobiliarias & Agentes en espera</div>
        </div>

        <div style={{ backgroundColor: '#161E2E', borderRadius: '12px', padding: '16px', border: '1px solid rgba(255,255,255,0.1)' }}>
          <div style={{ color: '#9CA3AF', fontSize: '12px', fontWeight: 'bold' }}>REPORTES DE VERACIDAD</div>
          <div style={{ fontSize: '28px', fontWeight: 'bold', color: '#10B981', marginTop: '4px' }}>02</div>
          <div style={{ color: '#6B7280', fontSize: '11px', marginTop: '4px' }}>Fotos RENDER vs Foto Real</div>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '8px', borderBottom: '1px solid rgba(255,255,255,0.1)', paddingBottom: '12px', marginBottom: '20px' }}>
        <button
          onClick={() => setSelectedTab('CASES')}
          style={{
            backgroundColor: selectedTab === 'CASES' ? '#0D9488' : 'transparent',
            color: selectedTab === 'CASES' ? '#FFF' : '#9CA3AF',
            border: 'none',
            padding: '8px 16px',
            borderRadius: '8px',
            cursor: 'pointer',
            fontWeight: 'bold',
            fontSize: '13px'
          }}
        >
          📋 Triaje de Casos (AdminCase)
        </button>

        <button
          onClick={() => setSelectedTab('GATE')}
          style={{
            backgroundColor: selectedTab === 'GATE' ? '#0D9488' : 'transparent',
            color: selectedTab === 'GATE' ? '#FFF' : '#9CA3AF',
            border: 'none',
            padding: '8px 16px',
            borderRadius: '8px',
            cursor: 'pointer',
            fontWeight: 'bold',
            fontSize: '13px'
          }}
        >
          🌐 Market Launch Compliance Gate
        </button>
      </div>

      {/* Content Area */}
      {selectedTab === 'CASES' && (
        <div>
          {/* Status Filter */}
          <div style={{ display: 'flex', gap: '8px', marginBottom: '16px' }}>
            {['ALL', 'NEW', 'TRIAGED', 'IN_REVIEW', 'RESOLVED'].map(st => (
              <button
                key={st}
                onClick={() => setFilterStatus(st)}
                style={{
                  backgroundColor: filterStatus === st ? '#161E2E' : 'transparent',
                  color: filterStatus === st ? '#14B8A6' : '#6B7280',
                  border: filterStatus === st ? '1px solid #14B8A6' : '1px solid transparent',
                  padding: '4px 12px',
                  borderRadius: '16px',
                  fontSize: '12px',
                  cursor: 'pointer'
                }}
              >
                {st}
              </button>
            ))}
          </div>

          {/* Cases Table */}
          <div style={{ backgroundColor: '#161E2E', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.1)', overflow: 'hidden' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
              <thead>
                <tr style={{ backgroundColor: 'rgba(255,255,255,0.03)', color: '#9CA3AF', borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
                  <th style={{ padding: '12px 16px' }}>ID & Prioridad</th>
                  <th style={{ padding: '12px 16px' }}>Tipo de Caso</th>
                  <th style={{ padding: '12px 16px' }}>Título & Descripción</th>
                  <th style={{ padding: '12px 16px' }}>Estado</th>
                  <th style={{ padding: '12px 16px' }}>Acciones de Triaje</th>
                </tr>
              </thead>
              <tbody>
                {filteredCases.map(item => (
                  <tr key={item.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                    <td style={{ padding: '12px 16px' }}>
                      <div style={{ fontWeight: 'bold' }}>{item.id}</div>
                      <span style={{
                        fontSize: '10px',
                        padding: '2px 6px',
                        borderRadius: '4px',
                        backgroundColor: item.priority === 'CRITICAL' ? 'rgba(239, 68, 68, 0.2)' : 'rgba(245, 158, 11, 0.2)',
                        color: item.priority === 'CRITICAL' ? '#EF4444' : '#F59E0B',
                        fontWeight: 'bold'
                      }}>
                        {item.priority}
                      </span>
                    </td>
                    <td style={{ padding: '12px 16px', color: '#14B8A6', fontWeight: '600' }}>
                      {item.caseType}
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      <div style={{ fontWeight: 'bold' }}>{item.title}</div>
                      <div style={{ color: '#9CA3AF', fontSize: '11px', marginTop: '2px' }}>{item.description}</div>
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      <span style={{
                        padding: '4px 8px',
                        borderRadius: '6px',
                        fontSize: '11px',
                        fontWeight: 'bold',
                        backgroundColor: item.status === 'RESOLVED' ? 'rgba(16, 185, 129, 0.2)' : 'rgba(255,255,255,0.1)',
                        color: item.status === 'RESOLVED' ? '#10B981' : '#F9FAFB'
                      }}>
                        {item.status}
                      </span>
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      <div style={{ display: 'flex', gap: '6px' }}>
                        {item.status !== 'RESOLVED' && (
                          <button
                            onClick={() => updateCaseStatus(item.id, 'RESOLVED')}
                            style={{
                              backgroundColor: '#10B981',
                              color: '#FFF',
                              border: 'none',
                              padding: '4px 10px',
                              borderRadius: '6px',
                              cursor: 'pointer',
                              fontSize: '11px',
                              fontWeight: 'bold'
                            }}
                          >
                            Aprobar / Resolver
                          </button>
                        )}
                        {item.status === 'NEW' && (
                          <button
                            onClick={() => updateCaseStatus(item.id, 'IN_REVIEW')}
                            style={{
                              backgroundColor: 'transparent',
                              color: '#14B8A6',
                              border: '1px solid #14B8A6',
                              padding: '4px 10px',
                              borderRadius: '6px',
                              cursor: 'pointer',
                              fontSize: '11px'
                            }}
                          >
                            Triar
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {selectedTab === 'GATE' && (
        <div style={{ backgroundColor: '#161E2E', padding: '20px', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.1)' }}>
          <h2 style={{ marginTop: 0, color: '#14B8A6', fontSize: '18px' }}>🌐 Market Launch Compliance Gate — Bolivia (BOL)</h2>
          <p style={{ color: '#9CA3AF', fontSize: '13px' }}>
            Puerta de habilitación comercial. Ninguna función de venta inmobiliaria o preventa se activa sin superar las 5 etapas:
          </p>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))', gap: '12px', marginTop: '16px' }}>
            <div style={{ backgroundColor: '#0B0F17', padding: '12px', borderRadius: '8px', borderLeft: '4px solid #10B981' }}>
              <div style={{ fontSize: '11px', color: '#10B981', fontWeight: 'bold' }}>1. RESEARCH</div>
              <div style={{ fontSize: '13px', fontWeight: 'bold', marginTop: '4px' }}>Ley 453 & DS 4732</div>
            </div>
            <div style={{ backgroundColor: '#0B0F17', padding: '12px', borderRadius: '8px', borderLeft: '4px solid #10B981' }}>
              <div style={{ fontSize: '11px', color: '#10B981', fontWeight: 'bold' }}>2. LEGAL_REVIEW</div>
              <div style={{ fontSize: '13px', fontWeight: 'bold', marginTop: '4px' }}>VDDUC Preventas</div>
            </div>
            <div style={{ backgroundColor: '#0B0F17', padding: '12px', borderRadius: '8px', borderLeft: '4px solid #10B981' }}>
              <div style={{ fontSize: '11px', color: '#10B981', fontWeight: 'bold' }}>3. TECH_READY</div>
              <div style={{ fontSize: '13px', fontWeight: 'bold', marginTop: '4px' }}>PostGIS & NestJS</div>
            </div>
            <div style={{ backgroundColor: '#0B0F17', padding: '12px', borderRadius: '8px', borderLeft: '4px solid #F59E0B' }}>
              <div style={{ fontSize: '11px', color: '#F59E0B', fontWeight: 'bold' }}>4. STORE_READY</div>
              <div style={{ fontSize: '13px', fontWeight: 'bold', marginTop: '4px' }}>Apple/Google IAP</div>
            </div>
            <div style={{ backgroundColor: '#0B0F17', padding: '12px', borderRadius: '8px', borderLeft: '4px solid #6B7280' }}>
              <div style={{ fontSize: '11px', color: '#6B7280', fontWeight: 'bold' }}>5. ENABLED</div>
              <div style={{ fontSize: '13px', fontWeight: 'bold', marginTop: '4px' }}>Lanzamiento Comercial</div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
