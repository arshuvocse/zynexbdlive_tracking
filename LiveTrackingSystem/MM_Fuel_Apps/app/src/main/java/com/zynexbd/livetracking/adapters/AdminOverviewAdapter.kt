package com.zynexbd.livetracking.adapters

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.zynexbd.livetracking.databinding.ItemAdminUserOverviewBinding
import com.zynexbd.livetracking.models.User

class AdminOverviewAdapter(
    private val onViewLocation: (User) -> Unit,
    private val onViewRouteHistory: (User) -> Unit
) : ListAdapter<User, AdminOverviewAdapter.ViewHolder>(DiffCallback) {

    private var originalList = listOf<User>()

    fun setAllUsers(list: List<User>) {
        originalList = list
        submitList(list)
    }

    fun filter(query: String) {
        if (query.isBlank()) {
            submitList(originalList)
        } else {
            val q = query.trim().lowercase()
            val filtered = originalList.filter {
                it.name.lowercase().contains(q) ||
                it.username.lowercase().contains(q) ||
                it.role.lowercase().contains(q) ||
                (it.phoneNumber?.lowercase()?.contains(q) == true)
            }
            submitList(filtered)
        }
    }

    class ViewHolder(val binding: ItemAdminUserOverviewBinding) : RecyclerView.ViewHolder(binding.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemAdminUserOverviewBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val user = getItem(position)
        with(holder.binding) {
            val displayName = user.name.ifBlank { user.username }
            textFullName.text = displayName
            textUsername.text = "@${user.username}"
            textAvatarInitials.text = displayName.firstOrNull()?.uppercaseChar()?.toString() ?: "U"
            textRole.text = user.role
            textCoordinates.text = "Phone: ${user.phoneNumber ?: "N/A"}"
            textDateTime.text = if (user.isActive) "Active Account" else "Disabled"

            if (user.isActive) {
                textAccountStatus.text = "Active"
                textAccountStatus.setTextColor(android.graphics.Color.parseColor("#059669"))
            } else {
                textAccountStatus.text = "Disabled"
                textAccountStatus.setTextColor(android.graphics.Color.parseColor("#DC2626"))
            }

            textAttendanceStatus.text = if (user.isActive) "ONLINE" else "OFFLINE"

            buttonViewLocation.setOnClickListener { onViewLocation(user) }
            buttonRouteHistory.setOnClickListener { onViewRouteHistory(user) }
        }
    }

    object DiffCallback : DiffUtil.ItemCallback<User>() {
        override fun areItemsTheSame(oldItem: User, newItem: User) = oldItem.id == newItem.id
        override fun areContentsTheSame(oldItem: User, newItem: User) = oldItem == newItem
    }
}
