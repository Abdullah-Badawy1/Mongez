import React from 'react';
import { Container, Row, Col, Button, Image } from 'react-bootstrap';
import { motion } from 'framer-motion';
import { useTranslation } from 'react-i18next';

function AppPromotion() {
  const { t } = useTranslation();

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.2,
        delayChildren: 0.1
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
        damping: 15
      }
    }
  };

  const floatVariants = {
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

  return (
    <section 
      className="app-promotion-section position-relative overflow-hidden py-6"
      style={{ 
        background: 'linear-gradient(135deg, #3173b5 0%, #2c3e50 100%)',
        color: 'white'
      }}
    >
      {/* Background Decorative Elements */}
      <div className="position-absolute top-0 start-0 w-100 h-100" style={{ zIndex: 0 }}>
        <motion.div
          animate={{ 
            rotate: 360,
            scale: [1, 1.1, 1]
          }}
          transition={{ 
            rotate: { duration: 20, repeat: Infinity, ease: "linear" },
            scale: { duration: 3, repeat: Infinity, repeatType: "reverse" }
          }}
          className="position-absolute"
          style={{ 
            top: '-10%',
            right: '-5%',
            width: '300px',
            height: '300px',
            background: 'radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%)',
            borderRadius: '50%'
          }}
        />
      </div>

      <Container className="position-relative" style={{ zIndex: 1 }}>
        <Row className="align-items-center">
          {/* Text Content */}
          <Col lg={6} className="mb-5 mb-lg-0">
            <motion.div
              variants={containerVariants}
              initial="hidden"
              whileInView="visible"
              viewport={{ once: true }}
            >
              <motion.div variants={itemVariants} className="mb-4">
                <span className="badge bg-white text-primary px-3 py-2 rounded-pill">
                  <i className="bi bi-star-fill me-2"></i>
                  {t('app_promotion_badge')}
                </span>
              </motion.div>

              <motion.h2 
                variants={itemVariants}
                className="display-4 fw-bold mb-3"
              >
                {t('app_promotion_title_part1')}{' '}
                <motion.span
                  style={{ display: 'inline-block' }}
                  animate={{ 
                    color: ['#ffffff', '#ffd700', '#ffffff']
                  }}
                  transition={{ duration: 2, repeat: Infinity }}
                >
                  {t('app_promotion_title_part2')}
                </motion.span>
              </motion.h2>

              <motion.p 
                variants={itemVariants}
                className="lead mb-4 opacity-90"
                style={{ lineHeight: 1.6 }}
              >
                {t('app_promotion_description')}
              </motion.p>

              {/* App Store Buttons */}
              <motion.div variants={itemVariants} className="mb-4">
                <div className="d-flex flex-wrap gap-3">
                  {[
                    {
                      icon: 'bi-apple',
                      storeKey: 'app_promotion_appstore',
                      subKey: 'app_promotion_appstore_sub',
                      color: 'light'
                    },
                    {
                      icon: 'bi-google-play',
                      storeKey: 'app_promotion_googleplay',
                      subKey: 'app_promotion_googleplay_sub',
                      color: 'dark'
                    }
                  ].map((app, idx) => (
                    <motion.div
                      key={idx}
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                    >
                      <Button
                        variant={app.color}
                        size="lg"
                        className="px-4 py-3 rounded-pill shadow-lg d-flex align-items-center"
                        style={{ 
                          border: 'none',
                          minWidth: '200px'
                        }}
                      >
                        <div className="me-3">
                          <i className={`bi ${app.icon} fs-2`}></i>
                        </div>
                        <div className="text-start">
                          <small className="d-block">{t(app.subKey)}</small>
                          <div className="fw-bold fs-5">{t(app.storeKey)}</div>
                        </div>
                      </Button>
                    </motion.div>
                  ))}
                </div>
              </motion.div>

              {/* Features */}
              <motion.div variants={itemVariants} className="d-flex flex-wrap gap-4">
                {[
                  { icon: 'bi-shield-check', textKey: 'app_promotion_feature1_text' },
                  { icon: 'bi-star-fill', textKey: 'app_promotion_feature2_text' },
                  { icon: 'bi-download', textKey: 'app_promotion_feature3_text' }
                ].map((feature, idx) => (
                  <div key={idx} className="d-flex align-items-center opacity-90">
                    <i className={`bi ${feature.icon} me-2`}></i>
                    <span>{t(feature.textKey)}</span>
                  </div>
                ))}
              </motion.div>
            </motion.div>
          </Col>

          {/* Image & QR Code */}
          <Col lg={6} className="text-center">
            <motion.div
              variants={floatVariants}
              animate="float"
              className="position-relative"
            >
              {/* Phone Mockup */}
              <div className="position-relative mb-4">
                <Image
                  src="https://images.unsplash.com/photo-1558618666-fcd25c85cd64?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80"
                  fluid
                  rounded
                  className="shadow-lg border border-4 border-white"
                  alt={t('app_promotion_image_alt')}
                  style={{ borderRadius: '25px' }}
                />
                
                {/* App Store Badges Overlay */}
                <motion.div
                  initial={{ y: 20, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  transition={{ delay: 0.5 }}
                  className="position-absolute bottom-0 start-50 translate-middle-x d-flex gap-2"
                  style={{ transform: 'translateX(-50%) translateY(50%)' }}
                >
                  {[1, 2].map((i) => (
                    <div
                      key={i}
                      className="bg-white rounded-pill px-3 py-1 shadow-sm"
                    >
                      <small className="text-dark">
                        <i className={`bi ${i === 1 ? 'bi-apple' : 'bi-google-play'} me-1`}></i>
                        {i === 1 ? t('app_promotion_ios_badge') : t('app_promotion_android_badge')}
                      </small>
                    </div>
                  ))}
                </motion.div>
              </div>

              {/* QR Code Card */}
              <motion.div
                initial={{ scale: 0.8, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ delay: 0.7, type: "spring" }}
                className="bg-white rounded-4 p-4 shadow-lg d-inline-block"
                style={{ maxWidth: '220px' }}
              >
                <div className="text-center mb-3">
                  <h6 className="text-dark fw-bold mb-1">{t('app_promotion_qr_title')}</h6>
                  <small className="text-muted">{t('app_promotion_qr_subtitle')}</small>
                </div>
                
                <motion.div
                  animate={{ 
                    boxShadow: [
                      '0 0 0 0 rgba(102, 126, 234, 0)',
                      '0 0 0 10px rgba(102, 126, 234, 0.2)',
                      '0 0 0 0 rgba(102, 126, 234, 0)'
                    ]
                  }}
                  transition={{ duration: 2, repeat: Infinity }}
                  className="bg-light rounded-3 p-3 mx-auto"
                  style={{ 
                    width: '150px',
                    height: '150px'
                  }}
                >
                  <div className="w-100 h-100 d-flex flex-column align-items-center justify-content-center">
                    <i className="bi bi-qr-code-scan fs-1 text-dark"></i>
                    <div className="mt-2">
                      <small className="text-muted d-block">{t('app_promotion_qr_mongez')}</small>
                      <small className="text-primary fw-bold">{t('app_promotion_qr_mobile_app')}</small>
                    </div>
                  </div>
                </motion.div>
              </motion.div>
            </motion.div>
          </Col>
        </Row>
      </Container>
    </section>
  );
}

export default AppPromotion;