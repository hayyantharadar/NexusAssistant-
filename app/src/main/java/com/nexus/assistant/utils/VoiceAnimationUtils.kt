package com.nexus.assistant.utils

import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import kotlin.math.abs
import kotlin.random.Random

object VoiceAnimationUtils {
    
    private var animatorSet: AnimatorSet? = null
    private val waveViews = mutableListOf<View>()
    
    fun startWaveAnimation(container: LinearLayout) {
        // Show wave bars
        for (i in 0 until container.childCount) {
            val child = container.getChildAt(i)
            if (child.id != android.R.id.text1) { // Skip placeholder text
                child.visibility = View.VISIBLE
                waveViews.add(child)
            }
        }
        
        // Hide placeholder text
        val placeholder = container.findViewById<View>(android.R.id.text1)
        placeholder?.visibility = View.GONE
        
        // Start animation
        animateWaves()
    }
    
    fun stopWaveAnimation(container: LinearLayout) {
        animatorSet?.cancel()
        animatorSet = null
        
        // Hide wave bars
        waveViews.forEach { view ->
            view.visibility = View.GONE
            view.scaleY = 1f
        }
        waveViews.clear()
        
        // Show placeholder text
        val placeholder = container.findViewById<View>(android.R.id.text1)
        placeholder?.visibility = View.VISIBLE
    }
    
    fun updateWaveAnimation(container: LinearLayout, volume: Float) {
        if (waveViews.isEmpty()) return
        
        // Normalize volume (typically -2 to 10 dB)
        val normalizedVolume = ((volume + 2f) / 12f).coerceIn(0.1f, 1f)
        
        waveViews.forEachIndexed { index, view ->
            val randomFactor = 0.7f + Random.nextFloat() * 0.6f
            val scale = normalizedVolume * randomFactor
            view.scaleY = scale
        }
    }
    
    private fun animateWaves() {
        if (waveViews.isEmpty()) return
        
        val animators = mutableListOf<ObjectAnimator>()
        
        waveViews.forEachIndexed { index, view ->
            val scaleY = ObjectAnimator.ofFloat(view, "scaleY", 0.3f, 1f, 0.3f)
            scaleY.duration = 800 + (index * 100L)
            scaleY.repeatCount = ObjectAnimator.INFINITE
            scaleY.repeatMode = ObjectAnimator.REVERSE
            animators.add(scaleY)
        }
        
        animatorSet = AnimatorSet()
        animatorSet?.playTogether(animators)
        animatorSet?.start()
    }
}

