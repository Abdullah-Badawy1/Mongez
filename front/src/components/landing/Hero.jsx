import React, { useEffect } from 'react';
import { Container, Row, Col, Button, Image, Badge } from 'react-bootstrap';
import { Link } from 'react-router-dom';
// eslint-disable-next-line no-unused-vars -- `motion` used as <motion.*> in JSX (lowercase, missed by no-unused-vars)
import { motion, useAnimation } from 'framer-motion';
import { useInView } from 'react-intersection-observer';
import { useTranslation } from 'react-i18next';

function Hero() {
  const { t } = useTranslation(); // استخدام الترجمة
  const controls = useAnimation();
  const [ref, inView] = useInView({
    threshold: 0.3,
    triggerOnce: true
  });

  useEffect(() => {
    if (inView) {
      controls.start('visible');
    }
  }, [controls, inView]);

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.2,
        delayChildren: 0.3
      }
    }
  };

  const itemVariants = {
    hidden: { y: 30, opacity: 0 },
    visible: {
      y: 0,
      opacity: 1,
      transition: {
        type: "spring",
        stiffness: 100,
        damping: 20
      }
    }
  };

  const floatingVariants = {
    float: {
      y: [-10, 10],
      transition: {
        y: {
          duration: 2,
          repeat: Infinity,
          repeatType: "reverse",
          ease: "easeInOut"
        }
      }
    }
  };

  // مصفوفة الإحصائيات مع مفاتيح الترجمة
  const stats = [
    { value: '15', unit: 'Min', labelKey: 'hero_stat_avg_response_time', icon: 'bi-lightning-fill' },
    { value: '10K+', unit: '', labelKey: 'hero_stat_happy_customers', icon: 'bi-people-fill' },
    { value: '4.9', unit: '/5', labelKey: 'hero_stat_rating', icon: 'bi-star-fill' }
  ];

  // مصفوفة الميزات مع مفاتيح الترجمة
  const features = [
    { icon: 'bi-shield-check', textKey: 'hero_feature_verified_technicians', color: '#2ecc71' },
    { icon: 'bi-clock-history', textKey: 'hero_feature_24_7_support', color: '#3498db' },
    { icon: 'bi-award', textKey: 'hero_feature_100_satisfaction', color: '#9b59b6' }
  ];

  return (
    <section 
      className="hero-section overflow-hidden position-relative"
      style={{ 
        background: 'linear-gradient(135deg, #f8faff 0%, #e6f0ff 100%)',
        padding: '120px 0 80px'
      }}
      ref={ref}
    >
      {/* Background Elements */}
      <div className="position-absolute top-0 start-0 w-100 h-100" 
           style={{ zIndex: 1, pointerEvents: 'none' }}>
        <div className="position-absolute top-0 end-0"
             style={{ 
               width: '600px',
               height: '600px',
               background: 'radial-gradient(circle, rgba(52, 152, 219, 0.1) 0%, transparent 70%)',
               transform: 'translate(30%, -30%)'
             }}></div>
        <div className="position-absolute bottom-0 start-0"
             style={{ 
               width: '400px',
               height: '400px',
               background: 'radial-gradient(circle, rgba(46, 204, 113, 0.1) 0%, transparent 70%)',
               transform: 'translate(-30%, 30%)'
             }}></div>
      </div>

      <Container className="position-relative" style={{ zIndex: 2 }}>
        <Row className="align-items-center g-5">
          <Col lg={6} className="mb-5 mb-lg-0">
            <motion.div
              variants={containerVariants}
              initial="hidden"
              animate={controls}
            >
              {/* Trust Badge */}
              <motion.div
                variants={itemVariants}
                whileHover={{ scale: 1.05 }}
              >
                <Badge 
                  bg="white"
                  className="d-inline-flex align-items-center px-3 py-2 mb-4 rounded-pill shadow-sm border-0"
                  style={{ 
                    background: 'rgba(255, 255, 255, 0.9) !important',
                    backdropFilter: 'blur(10px)'
                  }}
                >
                  <motion.span 
                    className="d-inline-block me-2"
                    animate={{ rotate: [0, 10, 0] }}
                    transition={{ duration: 2, repeat: Infinity }}
                  >
                    🚀
                  </motion.span>
                  <span className="text-dark fw-medium">{t('hero_trusted_badge')}</span>
                  <motion.div 
                    className="ms-2"
                    style={{ 
                      width: '8px',
                      height: '8px',
                      backgroundColor: '#2ecc71',
                      borderRadius: '50%',
                      animation: 'pulse 2s infinite'
                    }}
                  />
                </Badge>
              </motion.div>

              {/* Main Headline */}
              <motion.h1
                variants={itemVariants}
                className="display-3 fw-bold mb-4"
                style={{ 
                  color: '#2c3e50',
                  lineHeight: '1.2'
                }}
              >
                {t('hero_main_headline_part1')}{' '}
                <motion.span 
                  className="text-gradient"
                  style={{
                    background: 'linear-gradient(45deg, #3498db, #2ecc71)',
                    WebkitBackgroundClip: 'text',
                    WebkitTextFillColor: 'transparent',
                    fontWeight: 800
                  }}
                  animate={{ 
                    backgroundPosition: ['0% 50%', '100% 50%', '0% 50%']
                  }}
                  transition={{ 
                    duration: 5,
                    repeat: Infinity,
                    ease: "linear"
                  }}
                >
                  {t('hero_main_headline_part2')}
                </motion.span>
              </motion.h1>

              {/* Subtitle */}
              <motion.p
                variants={itemVariants}
                className="lead mb-4"
                style={{ 
                  color: '#6c757d',
                  fontSize: '1.25rem',
                  lineHeight: '1.6'
                }}
              >
                {t('hero_subtitle')}
              </motion.p>

              {/* Features List */}
              <motion.div
                variants={itemVariants}
                className="mb-5"
              >
                <div className="row g-3">
                  {features.map((feature, index) => (
                    <Col xs={12} sm={4} key={index}>
                      <div className="d-flex align-items-center">
                        <div 
                          className="rounded-circle p-2 me-3"
                          style={{ 
                            backgroundColor: `${feature.color}20`,
                            width: '40px',
                            height: '40px',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center'
                          }}
                        >
                          <i className={`bi ${feature.icon}`} style={{ color: feature.color }}></i>
                        </div>
                        <span className="fw-medium" style={{ color: '#495057' }}>
                          {t(feature.textKey)}
                        </span>
                      </div>
                    </Col>
                  ))}
                </div>
              </motion.div>

              {/* CTA Buttons */}
              <motion.div
                variants={itemVariants}
                className="d-flex flex-wrap gap-3 mb-5"
              >
                <motion.div
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  <Button 
                    as={Link}
                    to="/download"
                    variant="primary"
                    size="lg"
                    className="px-5 py-3 rounded-pill shadow-lg border-0 d-flex align-items-center"
                    style={{ 
                      background: 'linear-gradient(135deg, #3498db 0%, #2ecc71 100%)',
                      fontWeight: '600',
                      position: 'relative',
                      overflow: 'hidden'
                    }}
                  >
                    <motion.span
                      animate={{ rotate: [0, 360] }}
                      transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
                      className="me-2"
                    >
                      <i className="bi bi-download fs-5"></i>
                    </motion.span>
                    {t('hero_download_button')}
                    <motion.div 
                      className="position-absolute"
                      style={{
                        top: '-50%',
                        left: '-50%',
                        width: '200%',
                        height: '200%',
                        background: 'linear-gradient(45deg, transparent 30%, rgba(255,255,255,0.2) 50%, transparent 70%)',
                        transform: 'rotate(45deg)',
                        transition: 'transform 0.5s'
                      }}
                      whileHover={{ x: '100%' }}
                    />
                  </Button>
                </motion.div>

                <motion.div
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  <Button 
                    as="a"
                    href="#how-it-works"
                    variant="outline-primary"
                    size="lg"
                    className="px-5 py-3 rounded-pill d-flex align-items-center"
                    style={{ 
                      color: '#3498db', 
                      borderWidth: '2px',
                      borderColor: '#3498db',
                      fontWeight: '600',
                      background: 'rgba(52, 152, 219, 0.1)'
                    }}
                  >
                    <motion.span
                      animate={{ x: [0, 5, 0] }}
                      transition={{ duration: 2, repeat: Infinity }}
                      className="me-2"
                    >
                      <i className="bi bi-play-circle fs-5"></i>
                    </motion.span>
                    {t('hero_how_it_works_button')}
                  </Button>
                </motion.div>
              </motion.div>

              {/* Stats Counter */}
              <motion.div
                variants={itemVariants}
                className="mt-5 pt-4 border-top"
              >
                <Row className="g-4">
                  {stats.map((stat, index) => (
                    <Col xs={4} key={index}>
                      <div className="text-center">
                        <div className="d-flex align-items-center justify-content-center mb-2">
                          <div 
                            className="rounded-circle p-2 me-2"
                            style={{ 
                              backgroundColor: '#e3f2fd',
                              width: '40px',
                              height: '40px',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center'
                            }}
                          >
                            <i className={`bi ${stat.icon}`} style={{ color: '#3498db' }}></i>
                          </div>
                          <div className="text-start">
                            <h3 className="fw-bold mb-0" style={{ color: '#2c3e50' }}>
                              {stat.value}
                              <span style={{ fontSize: '1rem', color: '#6c757d' }}>{stat.unit}</span>
                            </h3>
                            <small className="text-muted">{t(stat.labelKey)}</small>
                          </div>
                        </div>
                      </div>
                    </Col>
                  ))}
                </Row>
              </motion.div>
            </motion.div>
          </Col>
          
          {/* Right Column - Image */}
          <Col lg={6}>
            <motion.div
              variants={floatingVariants}
              animate="float"
              className="position-relative"
            >
              {/* Main Image Container */}
              <div className="position-relative">
                {/* Main Image */}
                <motion.div
                  initial={{ scale: 0.8, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  transition={{ duration: 0.8, delay: 0.5 }}
                  className="position-relative"
                >
                  <Image 
                    src="https://images.unsplash.com/photo-1621905252507-b35492cc74b4?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80"
                    fluid 
                    rounded
                    className="shadow-lg"
                    alt={t('hero_image_alt')} // أضف هذا المفتاح في الترجمة
                    style={{ 
                      borderRadius: '20px',
                      transform: 'perspective(1000px) rotateY(-5deg)',
                      border: 'none'
                    }}
                  />
                  
                  {/* Image Overlay Gradient */}
                  <div 
                    className="position-absolute top-0 start-0 w-100 h-100 rounded"
                    style={{ 
                      background: 'linear-gradient(45deg, rgba(52, 152, 219, 0.1) 0%, rgba(46, 204, 113, 0.1) 100%)',
                      zIndex: 1,
                      pointerEvents: 'none'
                    }}
                  ></div>
                </motion.div>

                {/* Floating Cards */}
                <motion.div
                  initial={{ x: -50, y: 50, opacity: 0 }}
                  animate={{ x: 0, y: 0, opacity: 1 }}
                  transition={{ duration: 0.8, delay: 0.8 }}
                  className="position-absolute top-0 start-0 bg-white shadow-lg rounded-3 p-3 d-none d-lg-block"
                  style={{ 
                    transform: 'translate(-30%, 30%)',
                    zIndex: 2,
                    maxWidth: '180px'
                  }}
                >
                  <div className="d-flex align-items-center">
                    <div className="bg-primary rounded-circle p-2 me-3">
                      <i className="bi bi-check-circle-fill text-white fs-5"></i>
                    </div>
                    <div>
                      <h6 className="mb-0 fw-bold" style={{ color: '#2c3e50' }}>{t('hero_floating_verified_title')}</h6>
                      <small className="text-muted">{t('hero_floating_verified_desc')}</small>
                    </div>
                  </div>
                </motion.div>

                <motion.div
                  initial={{ x: 50, y: -50, opacity: 0 }}
                  animate={{ x: 0, y: 0, opacity: 1 }}
                  transition={{ duration: 0.8, delay: 1 }}
                  className="position-absolute top-0 end-0 bg-white shadow-lg rounded-3 p-3 d-none d-lg-block"
                  style={{ 
                    transform: 'translate(30%, -30%)',
                    zIndex: 2,
                    maxWidth: '180px'
                  }}
                >
                  <div className="d-flex align-items-center">
                    <div className="bg-success rounded-circle p-2 me-3">
                      <i className="bi bi-clock-fill text-white fs-5"></i>
                    </div>
                    <div>
                      <h6 className="mb-0 fw-bold" style={{ color: '#2c3e50' }}>{t('hero_floating_24_7_title')}</h6>
                      <small className="text-muted">{t('hero_floating_24_7_desc')}</small>
                    </div>
                  </div>
                </motion.div>

                <motion.div
                  initial={{ y: 50, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  transition={{ duration: 0.8, delay: 1.2 }}
                  className="position-absolute bottom-0 start-50 bg-white shadow-lg rounded-3 p-3 d-none d-lg-block"
                  style={{ 
                    transform: 'translateX(-50%) translateY(50%)',
                    zIndex: 2,
                    minWidth: '200px'
                  }}
                >
                  <div className="text-center">
                    <div className="d-flex align-items-center justify-content-center mb-2">
                      <div className="bg-warning rounded-circle p-2 me-2">
                        <i className="bi bi-star-fill text-white fs-5"></i>
                      </div>
                      <div>
                        <h4 className="mb-0 fw-bold" style={{ color: '#2c3e50' }}>4.9</h4>
                        <small className="text-muted">{t('hero_floating_rating_label')}</small>
                      </div>
                    </div>
                    <div className="text-warning">
                      <i className="bi bi-star-fill"></i>
                      <i className="bi bi-star-fill"></i>
                      <i className="bi bi-star-fill"></i>
                      <i className="bi bi-star-fill"></i>
                      <i className="bi bi-star-half"></i>
                    </div>
                  </div>
                </motion.div>
              </div>

              {/* Decorative Elements */}
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
                className="position-absolute top-50 start-0 translate-middle-y d-none d-lg-block"
                style={{ 
                  width: '100px',
                  height: '100px',
                  background: 'linear-gradient(45deg, transparent 50%, rgba(52, 152, 219, 0.1) 50%)',
                  borderRadius: '50%',
                  zIndex: 0
                }}
              />
              
              <motion.div
                animate={{ rotate: -360 }}
                transition={{ duration: 25, repeat: Infinity, ease: "linear" }}
                className="position-absolute bottom-0 end-0 d-none d-lg-block"
                style={{ 
                  width: '150px',
                  height: '150px',
                  background: 'linear-gradient(45deg, transparent 50%, rgba(46, 204, 113, 0.1) 50%)',
                  borderRadius: '50%',
                  zIndex: 0
                }}
              />
            </motion.div>
          </Col>
        </Row>
      </Container>

      {/* Scroll Indicator */}
      <motion.div 
        className="position-absolute bottom-0 start-50 translate-middle-x d-none d-md-block"
        animate={{ y: [0, 10, 0] }}
        transition={{ duration: 2, repeat: Infinity }}
        style={{ zIndex: 2 }}
      >
        <div className="text-center">
          <div className="mb-2">
            <i className="bi bi-mouse text-muted fs-4"></i>
          </div>
          <div className="scroll-line mx-auto"
               style={{ 
                 width: '1px',
                 height: '40px',
                 background: 'linear-gradient(to bottom, #3498db, transparent)'
               }}></div>
        </div>
      </motion.div>

      <style>
        {`
          @keyframes gradientShift {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
          }
          
          @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
          }
          
          .text-gradient {
            background-size: 200% auto;
            animation: gradientShift 5s ease infinite;
          }
          
          .hero-section {
            min-height: 100vh;
            display: flex;
            align-items: center;
          }
          
          @media (max-width: 992px) {
            .hero-section {
              padding: 100px 0 60px !important;
            }
            
            .display-3 {
              font-size: 2.5rem !important;
            }
          }
          
          .shadow-lg {
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1) !important;
          }
        `}
      </style>
    </section>
  );
}

export default Hero;