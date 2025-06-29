package com.nexus.assistant.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.nexus.assistant.databinding.ItemCommandBinding
import com.nexus.assistant.model.Command

class CommandAdapter(
    private val commands: List<Command>,
    private val onCommandClick: (Command) -> Unit
) : RecyclerView.Adapter<CommandAdapter.CommandViewHolder>() {
    
    inner class CommandViewHolder(private val binding: ItemCommandBinding) : 
        RecyclerView.ViewHolder(binding.root) {
        
        fun bind(command: Command) {
            binding.apply {
                tvCommandTitle.text = command.title
                tvCommandDescription.text = command.description
                ivCommandIcon.setImageResource(command.iconResId)
                
                cardCommand.setOnClickListener {
                    onCommandClick(command)
                }
            }
        }
    }
    
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): CommandViewHolder {
        val binding = ItemCommandBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return CommandViewHolder(binding)
    }
    
    override fun onBindViewHolder(holder: CommandViewHolder, position: Int) {
        holder.bind(commands[position])
    }
    
    override fun getItemCount(): Int = commands.size
}

