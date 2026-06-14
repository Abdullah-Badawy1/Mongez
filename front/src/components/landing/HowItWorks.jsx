import React from 'react';
import { Container, Row, Col, Button } from 'react-bootstrap';
import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';
import { useTranslation } from 'react-i18next';

function HowItWorks() {
  const { t } = useTranslation();
  const [ref, inView] = useInView({
    threshold: 0.2,
    triggerOnce: true
  });

  const steps = [
    {
      id: 1,
      titleKey: 'how_it_works_step1_title',
      descriptionKey: 'how_it_works_step1_desc',
      icon: 'bi-search-heart',
      subSteps: [
        'how_it_works_step1_sub1',
        'how_it_works_step1_sub2',
        'how_it_works_step1_sub3'
      ]
    },
    {
      id: 2,
      titleKey: 'how_it_works_step2_title',
      descriptionKey: 'how_it_works_step2_desc',
      icon: 'bi-person-check',
      subSteps: [
        'how_it_works_step2_sub1',
        'how_it_works_step2_sub2',
        'how_it_works_step2_sub3'
      ]
    },
    {
      id: 3,
      titleKey: 'how_it_works_step3_title',
      descriptionKey: 'how_it_works_step3_desc',
      icon: 'bi-check-all',
      subSteps: [
        'how_it_works_step3_sub1',
        'how_it_works_step3_sub2',
        'how_it_works_step3_sub3'
      ]
    }
  ];

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.3,
        delayChildren: 0.2
      }
    }
  };

  const stepVariants = {
    hidden: { y: 50, opacity: 0, scale: 0.9 },
    visible: {
      y: 0,
      opacity: 1,
      scale: 1,
      transition: {
        type: "spring",
        stiffness: 100,
        damping: 15
      }
    },
    hover: {
      y: -15,
      transition: {
        type: "spring",
        stiffness: 400,
        damping: 25
      }
    }
  };

  const numberVariants = {
    hidden: { scale: 0, rotate: -180 },
    visible: {
      scale: 1,
      rotate: 0,
      transition: {
        type: "spring",
        stiffness: 200,
        damping: 15
      }
    },
    hover: {
      rotate: 360,
      transition: {
        duration: 0.8,
        ease: "easeInOut"
      }
    }
  };

  const lineVariants = {
    hidden: { scaleX: 0 },
    visible: {
      scaleX: 1,
      transition: {
        duration: 1,
        ease: "easeInOut"
      }
    }
  };

  return (
    <section 
      ref={ref}
      className="how-it-works-section position-relative py-6 overflow-hidden"
      id="how-it-works"
      style={{ 
        background: 'linear-gradient(135deg, #f8faff 0%, #ffffff 100%)'
      }}
    >
      {/* Background Decorative Elements */}
      <div className="position-absolute top-0 start-0 w-100 h-100" style={{ zIndex: 0 }}>
        <div className="position-absolute" 
             style={{ 
               top: '10%',
               left: '5%',
               width: '200px',
               height: '200px',
               background: 'radial-gradient(circle, rgba(52, 152, 219, 0.08) 0%, transparent 70%)',
               borderRadius: '50%'
             }}></div>
        <div className="position-absolute" 
             style={{ 
               bottom: '20%',
               right: '10%',
               width: '300px',
               height: '300px',
               background: 'radial-gradient(circle, rgba(46, 204, 113, 0.05) 0%, transparent 70%)',
               borderRadius: '50%'
             }}></div>
      </div>

      <Container className="position-relative" style={{ zIndex: 1 }}>
        {/* Section Header */}
        <motion.div
          initial={{ opacity: 0, y: -30 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.6 }}
          className="text-center mb-6"
        >
          <div className="d-inline-block position-relative mb-4">
            <span className="badge bg-primary bg-opacity-10 text-primary px-4 py-2 rounded-pill fw-medium">
              <i className="bi bi-play-circle me-2"></i>
              {t('how_it_works_badge')}
            </span>
          </div>
          
          <h2 className="display-4 fw-bold mb-3" style={{ color: '#1a2530' }}>
            {t('how_it_works_title_part1')} <span style={{ color: '#3498db' }}>Mongez</span> {t('how_it_works_title_part2')}
          </h2>
          
          <p className="lead text-muted mx-auto" style={{ maxWidth: '700px' }}>
            {t('how_it_works_subtitle')}
          </p>
        </motion.div>

        {/* Steps Container */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate={inView ? "visible" : "hidden"}
          className="position-relative"
        >
          {/* Connecting Lines for Desktop */}
          <div className="d-none d-lg-block position-absolute top-0 start-0 w-100 h-100" 
               style={{ zIndex: 0, paddingTop: '140px' }}>
            <div className="position-relative h-100">
              <motion.div
                variants={lineVariants}
                className="position-absolute top-0 start-0 w-100"
                style={{
                  height: '4px',
                  background: 'linear-gradient(90deg, #3498db, #2ecc71)',
                  opacity: 0.15,
                  transformOrigin: 'left center',
                  top: '50%',
                  transform: 'translateY(-50%)'
                }}
              ></motion.div>
              
              {steps.map((step, index) => (
                <div 
                  key={step.id}
                  className="position-absolute"
                  style={{ 
                    left: `${(index + 0.5) * (100 / steps.length)}%`,
                    top: '50%',
                    transform: 'translate(-50%, -50%)'
                  }}
                >
                  <motion.div
                    animate={{ 
                      scale: [1, 1.2, 1],
                      opacity: [0.3, 0.6, 0.3]
                    }}
                    transition={{ 
                      duration: 2, 
                      repeat: Infinity,
                      delay: index * 0.5 
                    }}
                    style={{
                      width: '20px',
                      height: '20px',
                      borderRadius: '50%',
                      backgroundColor: '#3498db'
                    }}
                  ></motion.div>
                </div>
              ))}
            </div>
          </div>

          {/* Steps */}
          <Row className="g-4 g-lg-5 position-relative" style={{ zIndex: 1 }}>
            {steps.map((step, index) => (
              <Col key={step.id} lg={4} className="mb-5 mb-lg-0">
                <motion.div
                  variants={stepVariants}
                  whileHover="hover"
                  className="h-100"
                >
                  <div className="h-100 d-flex flex-column align-items-center text-center">
                    {/* Step Number */}
                    <motion.div
                      variants={numberVariants}
                      whileHover="hover"
                      className="position-relative mb-4"
                    >
                      <div 
                        className="rounded-circle d-flex align-items-center justify-content-center position-relative"
                        style={{ 
                          width: '120px',
                          height: '120px',
                          background: 'linear-gradient(135deg, #3498db, #2ecc71)',
                          color: 'white',
                          fontSize: '3rem',
                          fontWeight: 'bold',
                          boxShadow: '0 15px 35px rgba(52, 152, 219, 0.25)'
                        }}
                      >
                        <span className="position-relative" style={{ zIndex: 2 }}>
                          {step.id}
                        </span>
                        
                        {/* Animated Ring */}
                        <motion.div
                          animate={{ 
                            scale: [1, 1.2, 1],
                            opacity: [0.7, 0, 0.7]
                          }}
                          transition={{ 
                            duration: 2, 
                            repeat: Infinity 
                          }}
                          className="position-absolute top-0 start-0 w-100 h-100 rounded-circle"
                          style={{ 
                            border: '3px solid rgba(255, 255, 255, 0.5)',
                            zIndex: 1
                          }}
                        ></motion.div>
                      </div>
                      
                      {/* Step Icon */}
                      <motion.div
                        className="position-absolute bottom-0 end-0"
                        whileHover={{ rotate: 15, scale: 1.1 }}
                      >
                        <div 
                          className="rounded-circle p-3 d-flex align-items-center justify-content-center shadow-lg"
                          style={{ 
                            backgroundColor: 'white',
                            width: '60px',
                            height: '60px',
                            border: '3px solid #3498db'
                          }}
                        >
                          <i className={`bi ${step.icon} fs-3`} style={{ color: '#3498db' }}></i>
                        </div>
                      </motion.div>
                    </motion.div>

                    {/* Step Title */}
                    <motion.h3
                      initial={{ opacity: 0, y: 20 }}
                      animate={inView ? { opacity: 1, y: 0 } : {}}
                      transition={{ delay: 0.4 + index * 0.1 }}
                      className="fw-bold mb-3"
                      style={{ 
                        color: '#1a2530',
                        fontSize: '1.75rem'
                      }}
                    >
                      {t(step.titleKey)}
                    </motion.h3>

                    {/* Step Description */}
                    <motion.p
                      initial={{ opacity: 0 }}
                      animate={inView ? { opacity: 1 } : {}}
                      transition={{ delay: 0.5 + index * 0.1 }}
                      className="text-muted mb-4"
                      style={{ lineHeight: 1.7 }}
                    >
                      {t(step.descriptionKey)}
                    </motion.p>

                    {/* Sub Steps */}
                    <motion.div
                      initial={{ opacity: 0, y: 20 }}
                      animate={inView ? { opacity: 1, y: 0 } : {}}
                      transition={{ delay: 0.6 + index * 0.1 }}
                      className="mt-auto w-100"
                    >
                      <div className="bg-white rounded-3 p-3 shadow-sm">
                        <h6 className="fw-semibold mb-3" style={{ color: '#3498db' }}>
                          <i className="bi bi-list-check me-2"></i>
                          {t('how_it_works_quick_steps_label')}
                        </h6>
                        <ul className="list-unstyled mb-0">
                          {step.subSteps.map((subStepKey, idx) => (
                            <motion.li 
                              key={idx}
                              initial={{ opacity: 0, x: -20 }}
                              animate={inView ? { opacity: 1, x: 0 } : {}}
                              transition={{ delay: 0.7 + index * 0.1 + idx * 0.1 }}
                              className="mb-2 d-flex align-items-center"
                            >
                              <div className="bg-primary bg-opacity-10 rounded-circle p-1 me-2">
                                <i className="bi bi-check-circle text-primary" style={{ fontSize: '0.8rem' }}></i>
                              </div>
                              <span className="text-muted small">{t(subStepKey)}</span>
                            </motion.li>
                          ))}
                        </ul>
                      </div>
                    </motion.div>

                    {/* Step Indicator for Mobile */}
                    <div className="d-lg-none position-absolute bottom-0 start-50 translate-middle-x">
                      {index < steps.length - 1 && (
                        <div className="text-muted">
                          <i className="bi bi-arrow-down fs-4"></i>
                        </div>
                      )}
                    </div>
                  </div>
                </motion.div>
              </Col>
            ))}
          </Row>
        </motion.div>

        {/* CTA Section */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ delay: 1.2 }}
          className="text-center mt-6 pt-4"
        >
          <div className="bg-gradient rounded-4 p-4 p-lg-5 shadow-lg position-relative overflow-hidden"
               style={{ 
                 background: 'linear-gradient(135deg, #3498db 0%, #2ecc71 100%)',
                 color: 'white'
               }}>
            
            {/* Background Pattern */}
            <div className="position-absolute top-0 start-0 w-100 h-100 opacity-10"
                 style={{ 
                   backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.2'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`
                 }}></div>

            <div className="position-relative" style={{ zIndex: 1 }}>
              <h3 className="fw-bold mb-3">{t('how_it_works_cta_title')}</h3>
              <p className="mb-4 opacity-90 mx-auto" style={{ maxWidth: '600px' }}>
                {t('how_it_works_cta_description')}
              </p>
              
              <motion.div
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="d-inline-block"
              >
                <Button
                  variant="light"
                  size="lg"
                  className="px-5 py-3 rounded-pill fw-bold shadow-lg d-flex align-items-center mx-auto"
                  style={{ 
                    color: '#3498db',
                    border: 'none'
                  }}
                >
                  <motion.div
                    animate={{ 
                      scale: [1, 1.1, 1],
                      boxShadow: ['0 0 0 0 rgba(255,255,255,0.7)', '0 0 0 20px rgba(255,255,255,0)', '0 0 0 0 rgba(255,255,255,0)']
                    }}
                    transition={{ 
                      duration: 2,
                      repeat: Infinity,
                      repeatDelay: 1
                    }}
                    className="rounded-circle bg-white p-3 me-3"
                  >
                    <i className="bi bi-play-fill fs-4" style={{ color: '#3498db' }}></i>
                  </motion.div>
                  {t('how_it_works_cta_button')}
                </Button>
              </motion.div>
              
              <p className="mt-3 small opacity-75">
                <i className="bi bi-clock me-1"></i>
                {t('how_it_works_cta_stats')}
              </p>
            </div>
          </div>
        </motion.div>
      </Container>

      <style>
        {`
          .how-it-works-section {
            position: relative;
          }
          
          .py-6 {
            padding-top: 5rem !important;
            padding-bottom: 5rem !important;
          }
          
          .mt-6 {
            margin-top: 5rem !important;
          }
          
          .bg-gradient {
            background-size: 200% auto;
            transition: background-position 0.5s ease;
          }
          
          .bg-gradient:hover {
            background-position: right center;
          }
          
          @media (max-width: 768px) {
            .py-6 {
              padding-top: 3rem !important;
              padding-bottom: 3rem !important;
            }
            
            .display-4 {
              font-size: 2.25rem !important;
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

export default HowItWorks;