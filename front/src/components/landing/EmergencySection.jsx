import React from 'react';
import { Container, Row, Col, Button } from 'react-bootstrap';
import { motion } from 'framer-motion';
import { useTranslation } from 'react-i18next';

function EmergencySection() {
  const { t } = useTranslation();

  const pulseAnimation = {
    initial: { scale: 1 },
    animate: { 
      scale: [1, 1.05, 1],
      transition: { 
        duration: 1.5,
        repeat: Infinity,
        ease: "easeInOut" 
      }
    }
  };

  const phoneRing = {
    initial: { rotate: 0 },
    animate: { 
      rotate: [0, 10, -10, 0],
      transition: { 
        duration: 0.5,
        repeat: Infinity,
        repeatDelay: 1
      }
    }
  };

  const floatAnimation = {
    initial: { y: 0 },
    animate: { 
      y: [-10, 10],
      transition: { 
        duration: 2,
        repeat: Infinity,
        repeatType: "reverse",
        ease: "easeInOut"
      }
    }
  };

  return (
    <section 
      className="emergency-section py-6 position-relative overflow-hidden"
      style={{ 
        background: 'linear-gradient(135deg, #ffffff 0%, #f8faff 100%)'
      }}
    >
      {/* Background Elements - بدون صور */}
      <div className="position-absolute top-0 start-0 w-100 h-100">
        {/* Animated Shapes بدون صور */}
        <motion.div
          animate={{ 
            scale: [1, 1.2, 1],
            opacity: [0.03, 0.06, 0.03]
          }}
          transition={{ 
            duration: 3,
            repeat: Infinity 
          }}
          className="position-absolute top-50 start-0 translate-middle-y rounded-circle"
          style={{ 
            width: '300px',
            height: '300px',
            background: 'radial-gradient(circle, rgba(231, 76, 60, 0.05) 0%, transparent 70%)',
            filter: 'blur(40px)'
          }}
        />
        
        {/* Decorative Geometric Shapes */}
        <div className="position-absolute top-0 end-0" 
             style={{ transform: 'translate(30%, -30%)' }}>
          <div className="position-relative">
            <div className="position-absolute rounded-circle"
                 style={{ 
                   width: '150px',
                   height: '150px',
                   background: 'linear-gradient(135deg, rgba(231, 76, 60, 0.1) 0%, transparent 70%)',
                   border: '1px dashed rgba(231, 76, 60, 0.2)'
                 }}></div>
          </div>
        </div>
      </div>

      <Container className="position-relative">
        <Row className="justify-content-center">
          <Col lg={10}>
            <div className="rounded-4 p-4 p-lg-5 border position-relative overflow-hidden"
                 style={{ 
                   background: 'rgba(255, 255, 255, 0.95)',
                   backdropFilter: 'blur(10px)',
                   borderColor: 'rgba(231, 76, 60, 0.3) !important',
                   boxShadow: '0 20px 40px rgba(0, 0, 0, 0.08), inset 0 1px 0 rgba(255, 255, 255, 0.1)'
                 }}>
              
              {/* Glowing Border Effect */}
              <div className="position-absolute top-0 start-0 w-100 h-100 rounded-4"
                   style={{ 
                     boxShadow: 'inset 0 0 50px rgba(231, 76, 60, 0.08)',
                     pointerEvents: 'none'
                   }}></div>

              <Row className="align-items-center g-4">
                {/* Left Content */}
                <Col lg={7} className="order-lg-1 order-2">
                  <motion.div
                    initial={{ opacity: 0, x: -30 }}
                    whileInView={{ opacity: 1, x: 0 }}
                    transition={{ duration: 0.6 }}
                    viewport={{ once: true }}
                  >
                    <div className="mb-4">
                      <span className="badge bg-danger bg-opacity-10 text-danger border border-danger border-opacity-30 px-4 py-2 rounded-pill d-inline-flex align-items-center mb-3">
                        <motion.i 
                          className="bi bi-exclamation-triangle-fill me-2"
                          animate={{ 
                            scale: [1, 1.3, 1],
                            rotate: [0, 10, -10, 0]
                          }}
                          transition={{ 
                            duration: 1.5,
                            repeat: Infinity 
                          }}
                        ></motion.i>
                        <span className="fw-bold">{t('emergency_response_badge')}</span>
                      </span>
                      
                      <h2 className="fw-bold mb-3" style={{ 
                        fontSize: '2.5rem',
                        color: '#2c3e50',
                        lineHeight: 1.2
                      }}>
                        {t('emergency_title_part1')}
                        <span className="d-block text-danger">{t('emergency_title_part2')}</span>
                      </h2>
                      
                      <p className="lead mb-4 text-muted" style={{ 
                        fontSize: '1.1rem'
                      }}>
                        {t('emergency_description')}
                      </p>
                    </div>

                    {/* Stats & CTA */}
                    <div className="d-flex flex-column flex-md-row align-items-start align-items-md-center gap-4">
                      <motion.div
                        variants={pulseAnimation}
                        initial="initial"
                        animate="animate"
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                      >
                        <Button 
                          variant="danger"
                          size="lg"
                          className="px-5 py-3 rounded-pill fw-bold shadow-lg border-0 d-flex align-items-center"
                          style={{ 
                            background: 'linear-gradient(135deg, #e74c3c 0%, #c0392b 100%)',
                            fontSize: '1.1rem'
                          }}
                        >
                          <motion.i 
                            className="bi bi-telephone-outbound-fill me-3 fs-4"
                            variants={phoneRing}
                            initial="initial"
                            animate="animate"
                          ></motion.i>
                          <div className="text-start">
                            <div className="small opacity-75 text-white">{t('emergency_hotline_label')}</div>
                            <div className="fs-4 fw-bold text-white">{t('emergency_phone')}</div>
                          </div>
                        </Button>
                      </motion.div>

                      <div style={{ color: '#2c3e50' }}>
                        <div className="d-flex align-items-center gap-3">
                          <div className="bg-light rounded-circle p-3 border border-danger border-opacity-20">
                            <i className="bi bi-clock-history fs-4 text-danger"></i>
                          </div>
                          <div>
                            <div className="text-muted">{t('emergency_response_time_label')}</div>
                            <div className="fw-bold fs-5">
                              <motion.span
                                animate={{ 
                                  color: ['#2c3e50', '#e74c3c', '#2c3e50']
                                }}
                                transition={{ 
                                  duration: 2,
                                  repeat: Infinity 
                                }}
                              >
                                {t('emergency_response_time_value')}
                              </motion.span>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Features */}
                    <div className="row g-3 mt-4">
                      {[
                        { icon: 'bi-shield-check', textKey: 'emergency_feature_licensed' },
                        { icon: 'bi-truck', textKey: 'emergency_feature_dispatch' },
                        { icon: 'bi-currency-dollar', textKey: 'emergency_feature_fees' }
                      ].map((feature, idx) => (
                        <Col key={idx} xs={4}>
                          <div className="text-center">
                            <div className="bg-light rounded-circle p-2 mb-2 mx-auto border border-danger border-opacity-10"
                                 style={{ width: '50px', height: '50px' }}>
                              <i className={`bi ${feature.icon} fs-5 text-danger`}></i>
                            </div>
                            <small className="text-muted">{t(feature.textKey)}</small>
                          </div>
                        </Col>
                      ))}
                    </div>
                  </motion.div>
                </Col>

                {/* Right Graphic - بدون صور */}
                <Col lg={5} className="order-lg-2 order-1 text-center">
                  <motion.div
                    variants={floatAnimation}
                    initial="initial"
                    animate="animate"
                    className="position-relative"
                  >
                    {/* Emergency Icon بدون صور */}
                    <div className="position-relative mx-auto"
                         style={{ 
                           maxWidth: '300px',
                           perspective: '1000px'
                         }}>
                      <motion.div
                        animate={{ 
                          rotateY: [0, 360],
                          rotateX: [0, 10, 0]
                        }}
                        transition={{ 
                          rotateY: { duration: 20, repeat: Infinity, ease: "linear" },
                          rotateX: { duration: 4, repeat: Infinity, ease: "easeInOut" }
                        }}
                        className="position-relative"
                      >
                        {/* Outer Ring */}
                        <div className="position-relative rounded-circle mx-auto"
                             style={{ 
                               width: '250px',
                               height: '250px',
                               background: 'radial-gradient(circle, rgba(231, 76, 60, 0.08) 0%, transparent 70%)',
                               border: '2px dashed rgba(231, 76, 60, 0.2)'
                             }}>
                          {/* Inner Circle */}
                          <motion.div
                            animate={{ 
                              scale: [1, 1.1, 1],
                              boxShadow: [
                                '0 0 20px rgba(231, 76, 60, 0.08)',
                                '0 0 40px rgba(231, 76, 60, 0.15)',
                                '0 0 20px rgba(231, 76, 60, 0.08)'
                              ]
                            }}
                            transition={{ 
                              duration: 2,
                              repeat: Infinity 
                            }}
                            className="position-absolute top-50 start-50 translate-middle rounded-circle d-flex align-items-center justify-content-center"
                            style={{ 
                              width: '180px',
                              height: '180px',
                              background: 'rgba(255, 255, 255, 0.95)',
                              border: '1px solid rgba(231, 76, 60, 0.15)',
                              boxShadow: '0 10px 30px rgba(231, 76, 60, 0.08)'
                            }}
                          >
                            {/* Center Icon */}
                            <div className="text-center">
                              <motion.div
                                animate={{ 
                                  scale: [1, 1.2, 1],
                                  rotate: [0, 360]
                                }}
                                transition={{ 
                                  scale: { duration: 1.5, repeat: Infinity },
                                  rotate: { duration: 4, repeat: Infinity, ease: "linear" }
                                }}
                                className="mb-3"
                              >
                                <i className="bi bi-lightning-charge-fill text-danger" 
                                   style={{ fontSize: '3.5rem' }}></i>
                              </motion.div>
                              
                              <div>
                                <h3 className="fw-bold mb-0 text-dark">{t('emergency_service_24_7')}</h3>
                                <small className="text-muted">{t('emergency_service_desc')}</small>
                              </div>
                            </div>
                          </motion.div>
                        </div>
                      </motion.div>

                      {/* Floating Numbers */}
                      <motion.div
                        animate={{ 
                          y: [-20, 20],
                          opacity: [0.7, 1, 0.7]
                        }}
                        transition={{ 
                          duration: 3,
                          repeat: Infinity,
                          ease: "easeInOut"
                        }}
                        className="position-absolute top-0 start-50 translate-middle-x"
                        style={{ marginTop: '-20px' }}
                      >
                        <div className="bg-danger text-white rounded-pill px-3 py-1 fw-bold shadow-sm">
                          <i className="bi bi-clock me-2"></i>
                          {t('emergency_floating_label')}
                        </div>
                      </motion.div>
                    </div>

                    {/* Emergency Features List */}
                    <div className="mt-4 pt-3">
                      <div className="row g-2">
                        {[
                          { icon: 'bi-check-circle', textKey: 'emergency_fast_dispatch' },
                          { icon: 'bi-check-circle', textKey: 'emergency_expert_technicians' },
                          { icon: 'bi-check-circle', textKey: 'emergency_quality_guarantee' }
                        ].map((item, idx) => (
                          <div key={idx} className="col-12">
                            <div className="d-flex align-items-center justify-content-center">
                              <div className="bg-danger bg-opacity-10 rounded-circle p-1 me-2">
                                <i className={`bi ${item.icon} text-danger`}></i>
                              </div>
                              <small className="text-muted">{t(item.textKey)}</small>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  </motion.div>
                </Col>
              </Row>
            </div>
          </Col>
        </Row>
      </Container>
    </section>
  );
}

export default EmergencySection;