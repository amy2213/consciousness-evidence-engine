-- Phase 10 hostile test: a measurement cannot claim VALIDATED consciousness specificity without validation.
DO $$
DECLARE msg text;
BEGIN
  BEGIN
    INSERT INTO measurements(
      measurement_id,measurement_type,label,measurement_type_code,operational_target,
      consciousness_specificity,consciousness_specificity_rationale
    ) VALUES (
      'TEST-MEAS-OVERCLAIM','neural signal','Interesting neural signal','PHYSIOLOGICAL_SIGNAL','GENERAL_COGNITION',
      'VALIDATED',''
    );
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS msg=MESSAGE_TEXT;
    IF position('validated consciousness specificity requires validation context and rationale' in msg)=0 THEN
      RAISE EXCEPTION 'measurement firewall failed for wrong reason: %',msg;
    END IF;
    RAISE NOTICE 'PASS MEASUREMENT_CONSCIOUSNESS_FIREWALL: %',msg;
    RETURN;
  END;
  RAISE EXCEPTION 'measurement consciousness overclaim unexpectedly succeeded';
END $$;
